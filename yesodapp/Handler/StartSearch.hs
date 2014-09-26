{-# LANGUAGE DeriveGeneric #-}

module Handler.StartSearch where

import Import

import Data.Attoparsec.Number
import Data.Maybe
import Data.Aeson
import Data.Aeson.Types (Result, Array)
import Data.Vector ((!?))
import Data.Maybe (fromJust, catMaybes)
import Database.Persist.Types
import qualified Data.HashMap.Strict as M
import qualified Data.Text as T
import qualified Data.Vector as V
import GHC.Generics
import Yesod.Auth

import Handler.GeoCode
import qualified Location as Loc
import Yelp
import Distances

-- Will probably need to incorporate some monad return
-- in order to utilize search.
searchWithLocations :: MonadIO m => [Loc.Location] -> m [Place]
searchWithLocations locations = 
  search $ Loc.averageLocation locations

-- Input, structured as:
-- {people: [{name, postal, phone?, location {lat,lng}}]}
-- unfortunate JSON name.

-- Special structure for input,
-- (Because it's annoying to demand personLocation input from
--  initial POST, absurd to keep it as Maybe).
data InputPerson = InputPerson
                   { name :: String
                   , postal :: String
                   , phone :: Maybe Int
                   } deriving (Generic)

-- Person isn't input with GeoLocation, so
-- we compute
personFromInput :: MonadIO m => InputPerson -> m Person
personFromInput input = do
  loc <- geocode $ show $ postal input
  return Person { personName = name input
                , personPostal = postal input
                , personPhone = phone input
                , personLocation = loc
                }

data Input = Input
             { people :: [InputPerson]
             } deriving (Generic)

instance ToJSON Input
instance FromJSON Input
instance ToJSON InputPerson
instance FromJSON InputPerson

ensureInDBandGetIdWith selectFilterFor p = do
  maybeEntity <- runDB $ selectFirst (selectFilterFor p) []
  case maybeEntity of
    Just e ->
      -- previously in DB
      return $ entityKey e
    Nothing ->
      -- wasn't previously in DB
      -- So, need to insert it.
      runDB $ insert p

postStartSearchR :: Handler Value
postStartSearchR = do
    maid <- maybeAuthId
    case maid of
        Nothing -> notAuthenticated
        Just authId ->
            authenticatedPostStartSearchR authId


-- Mostly doing it this way to save indentation,
-- be easier to reason/think about,
-- and so there isn't a huge diff.
authenticatedPostStartSearchR authId = do
  -- Get input
  -- input in form: {people: [{...,postcode,...}]}
  -- Until API is fixed, just use raw JSON Value.
  inputJSON <- requireJsonBody

  inputPeople <- mapM personFromInput $ people inputJSON

  -- Get PeopleId for the corresponding input from Database
  -- where the row has a phonenumber,
  -- or the name + postal is the same.
  -- :: [Key Person] a.k.a [PersonId]
  -- selectKeysList is a bitch. :/

  let nameAndPostalFilter p = [ PersonName   ==. (personName p)
                              , PersonPostal ==. (personPostal p)]
      phoneNumberFilter   p = [ PersonPhone  ==. (personPhone p)]
      selectPersonFilterFor  p = (nameAndPostalFilter p) ||. (phoneNumberFilter p)

  peopleIds <- mapM
               (ensureInDBandGetIdWith selectPersonFilterFor)
               inputPeople


  foundPlaces <- searchWithLocations $ map personLocation inputPeople

  -- Similar to peopleIds above, need to try finding entity in DB,
  -- or insert if doesn't exist.
  let selectPlaceFilterFor p = [PlaceYelpid ==. (placeYelpid p)]

  placeIds <- mapM
              (ensureInDBandGetIdWith selectPlaceFilterFor)
              foundPlaces



  -- Number is the type Aeson uses for its JSON,
  -- fromIntegral coerces between number types.
  let newSearch = Search
                  { searchPeople = peopleIds
                  , searchFilters = []
                  , searchChosen = Nothing
                  , searchPlaces = placeIds
                  }
  newSearchId <- runDB $ insert newSearch

  -- Now we have the searchId, put it into the database
  _ <- runDB $ insert $ AuthorizedFor authId newSearchId

  -- PersistInt64, which is a PersistValue
  let keyPersistValue = unKey newSearchId
      grabInt64 (PersistInt64 x) = x
      keyInt64 = grabInt64 keyPersistValue



  -- TO GET DISTANCE & INSERT INTO SEARCHPLACE TABLE
  -- Extract all destination locations
  let grabInt64 (PersistInt64 x) = x
      placeNumbers = map (\x -> grabInt64 $ unKey x) placeIds
  maybePlaceLocs <- mapM (\p -> runDB $ get p) placeIds
  let placeLocs = map placeLocation $ catMaybes maybePlaceLocs
  --Extract all origin locations
      originLocs = map personLocation inputPeople
  -- Get all distance. Retrieves array of arrays
  allDistances <- mapM (\d -> getDistancesOriginListToDestination originLocs d) placeLocs
  --Insert into SearchPlace table
  let input1 = zip placeIds allDistances
  mapM_ (\(p,d) -> runDB $ insert $ SearchPlace newSearchId p d) input1


  -- Return {searchId: int}
  return $ object ["searchId" .= (fromIntegral keyInt64 :: Number)]

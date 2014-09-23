{-# LANGUAGE DeriveGeneric #-}

module Handler.StartSearch where

import Import

import Data.Attoparsec.Number
import Data.Aeson
import Data.Aeson.Types (Result, Array)
import Data.Vector ((!?))
import Data.Maybe (fromJust, catMaybes)
import Database.Persist.Types
import qualified Data.HashMap.Strict as M
import qualified Data.Text as T
import qualified Data.Vector as V
import GHC.Generics

import Handler.GeoCode
import qualified Location as Loc

-- Will probably need to incorporate some monad return
-- in order to utilize search.
search :: [Loc.Location] -> [Place]
search locations =
  undefined

-- Input, structured as:
-- {people: [{name, postal, phone?, location {lat,lng}}]}
-- unfortunate JSON name.

-- Special structure for input,
-- (Because it's annoying to demand personLocation input from
--  initial POST, absurd to keep it as Maybe).
data InputPerson = InputPerson
                   { name :: String
                   , postal :: Int
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

postStartSearchR :: Handler Value
postStartSearchR = do
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
               (\p ->do
                 maybePersonEntity <- runDB $ selectFirst (selectPersonFilterFor p) []
                 case maybePersonEntity of
                   Just personEntity ->
                    -- Person previously in DB
                    return $ entityKey personEntity
                   Nothing ->
                    -- Person wasn't previously in DB
                    -- So, need to insert them.
                    runDB $ insert p)
               inputPeople

  let newSearch = Search
                  { searchPeople = peopleIds
                  , searchFilters = []
                  , searchChosen = Nothing
                  , searchPlaces = []
                  }
  newSearchId <- runDB $ insert newSearch

  -- TODO: Average the locations
  -- TODO: Use `Location -> [Place]`: 1) put Place in DB table(s), 2) PlaceIDs

  -- PersistInt64, which is a PersistValue
  let keyPersistValue = unKey newSearchId
      grabInt64 (PersistInt64 x) = x
      keyInt64 = grabInt64 keyPersistValue

  -- Number is the type Aeson uses for its JSON,
  -- fromIntegral coerces between number types.

  -- Return {searchId: int}
  return $ object ["searchId" .= (fromIntegral keyInt64 :: Number)]

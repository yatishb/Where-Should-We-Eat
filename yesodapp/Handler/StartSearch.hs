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

-- Input, structured as:
-- {people: [{name, postal, phone?, location {lat,lng}}]}
-- unfortunate JSON name.
data Input = Input
             { people :: [Person]
             } deriving (Generic)

instance ToJSON Input
instance FromJSON Input

-- From the fantastic http://dev.stephendiehl.com/hask/
-- Pull a key out of an JSON object.
(^?) :: Value -> T.Text -> Maybe Value
(^?) (Object obj) k = M.lookup k obj
(^?) _ _ = Nothing

-- Pull the ith value out of a JSON list.
ix :: Value -> Int -> Maybe Value
ix (Array arr) i = arr !? i
ix _ _ = Nothing

postStartSearchR :: Handler Value
postStartSearchR = do
  -- Get input
  -- input in form: {people: [{...,postcode,...}]}
  -- Until API is fixed, just use raw JSON Value.
  inputJSON <- requireJsonBody

  -- "Dangerous" to use fromJust..
  -- once API fixed, can move to generic fromJSON
  let inputPeople = people inputJSON

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

  -- TODO: Need to go away and update searchPlaces later.

  -- PersistInt64, which is a PersistValue
  let keyPersistValue = unKey newSearchId
      grabInt64 (PersistInt64 x) = x
      keyInt64 = grabInt64 keyPersistValue

  -- Number is the type Aeson uses for its JSON,
  -- fromIntegral coerces between number types.

  -- Return {searchId: int}
  return $ object ["searchId" .= (fromIntegral keyInt64 :: Number)]

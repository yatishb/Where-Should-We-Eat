module Handler.StartSearch where

import Import

import Data.Attoparsec.Number
import Database.Persist.Types

{-

Skeleton stuff,
Insert a new post into DB.

Input: Not yet settled;
  * Might be JSON [PostalCode]
  * Would prefer {people:[{postalcode:""}]}

Schema: (from config/models)
    Searches
      people [PeopleId]
      filters [String]
      chosen PlaceId
      places [PlaceId]

Output: JSON {searchId: int}

-}

postStartSearchR :: Handler Value
postStartSearchR = do
  -- Get input

  -- Get PeopleId for the corresponding input from Database
  {-

  This involves being able to *uniquely* identify someone,
  from input
  based on either
    Person's name + postal
  or
    Person's phone

  Either loading from DB if this Person exists in DB,
  or inserting this Person in DB if don't exist.

  (Do we need Data Person, et al. ADT
   for our App?? Does Persistent give us that?
   YES! There should be a type People, Searches)
  TODO: Tables should be named for individual nouns/types,
        NOT plural/collective.

  Since that's dependent on internal API,
  (and some sample test case)
  let's leave that for later.

  -}

  let newSearch = Searches
                  { searchesPeople = []
                  , searchesFilters = []
                  , searchesChosen = Nothing
                  , searchesPlaces = []
                  }
  newSearchId <- runDB $ insert newSearch

  -- PersistInt64, which is a PersistValue
  let keyPersistValue = unKey newSearchId
      grabInt64 (PersistInt64 x) = x
      keyInt64 = grabInt64 keyPersistValue

  -- Number is the type Aeson uses for its JSON,
  -- fromIntegral coerces between number types.

  -- Return {searchId: int}
  return $ object ["searchId" .= (fromIntegral keyInt64 :: Number)]

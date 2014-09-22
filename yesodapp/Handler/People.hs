module Handler.People where

import Import
import Data.Aeson.Types
import Data.Maybe (catMaybes)
import qualified Data.Vector as V

getPeopleR :: SearchesId -> Handler Value
getPeopleR searchId = do
  -- read up on http://hackage.haskell.org/package/persistent-1.3.3/docs/Database-Persist-Class.html

  -- Get the corresponding row from the Id
  maybeSearchEntry <- runDB $ get searchId

  case maybeSearchEntry of
    Nothing -> return $
      -- TODO: Return some kind of error?
      object ["people" .= (V.empty :: Array)]

    Just searchEntry -> do
      -- Extract from people column of Searches table
      --     people :: [PeopleId]
      let peopleIds = searchesPeople searchEntry

      -- Then get these entries from the People table,
      --  and output as JSON.

      -- [PeopleId] to [Maybe PersistEntity People],
      -- then [PersistEntity People] without the Nothing ones
      -- (Get the PersistEntity People rather than People, so we can
      --  use entityIdToJSON)
      maybePeople <- mapM (\pId -> runDB $ get pId) peopleIds
      let people = catMaybes maybePeople

          -- There's surely a better way than this?
          -- e.g. GHC Generics? Though the record is from TH.
          peopleValues = flip map people $ \person ->
            object
            [ "name"   .= peopleName person
            , "postal" .= peoplePostal person
            -- , "phone " .= ???
            , "location" .= object
                            [ "lat" .= peopleLat person
                            , "lng" .= peopleLng person
                            ]
            ]

      -- Can persistent automatically do JSON? I think so.
      -- Kindof.
      -- Database.Persist.listToJSON :: [PersistValue] -> Text,
      -- Database.Persist.Class.entityIdToJSON :: ToJSON e => Entity e -> Value

      -- People {name, postal :: Int, phone Int Maybe, lat, lng}

      -- Return {people: [{name, postal, phone , location {lat, lng}}]}
      -- Aeson Arrays are Haskell vectors
      return $ object ["people" .= V.fromList peopleValues]

module Handler.People where

import Import
import Data.Aeson.Types
import Data.Maybe (catMaybes)
import qualified Data.Vector as V

getPeopleR :: SearchId -> Handler Value
getPeopleR searchId = do
  -- read up on http://hackage.haskell.org/package/persistent-1.3.3/docs/Database-Persist-Class.html

  -- Get the corresponding row from the Id
  maybeSearchEntry <- runDB $ get searchId

  case maybeSearchEntry of
    Nothing -> return $
      object [ "error"  .= ("No such search with id" :: Text)
             , "people" .= (V.empty :: Array)
             ]

    Just searchEntry -> do
      -- Extract from people column of Searches table
      --     people :: [PeopleId]
      let peopleIds = searchPeople searchEntry

      -- Then get these entries from the People table,
      --  and output as JSON.

      -- [PeopleId] to [Maybe People],
      -- then [People] without the Nothing ones
      maybePeople <- mapM (\pId -> runDB $ get pId) peopleIds
      let people = catMaybes maybePeople
          peopleValues = map toJSON people

      -- Return {people: [{name, postal, phone , location {lat, lng}}]}
      -- Aeson Arrays are Haskell vectors
      return $ object ["people" .= V.fromList peopleValues]

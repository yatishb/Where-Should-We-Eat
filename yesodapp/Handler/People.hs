module Handler.People where

import Import
import Data.Aeson.Types
import Data.Vector as V

getPeopleR :: SearchesId -> Handler Value
getPeopleR searchId = do
  -- Get the corresponding row from the Id
  searchEntries <- runDB $ selectList [SearchesId ==. searchId] [LimitTo 1]

  -- TODO: Extract from people column of Searches table
  --         people :: [PeopleId]

  -- let searchEntry = head searchEntries
  --     peopleArr = SearchesPeople $ entityVal searchEntries

  -- TODO: Then get these entries from the People table,
  --       and output as JSON.
  -- Can persistent automatically do JSON? I think so.

  -- Return {searchId: int}
  -- Aeson Arrays are Haskell vectors
  return $ object ["people" .= (V.empty :: Array)]

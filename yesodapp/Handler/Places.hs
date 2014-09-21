module Handler.Places where

import Import
import Data.Aeson.Types
import Data.Vector as V

getPlacesR :: SearchesId -> Handler Value
getPlacesR searchId = do
  -- Get the corresponding row from the Id
  searchEntries <- runDB $ selectList [SearchesId ==. searchId] [LimitTo 1]

  -- TODO: Extract from places column of Searches table
  --         places :: [PlaceId]

  -- let searchEntry = head searchEntries

  -- TODO: Then get these entries from the Place table,
  --       and output as JSON.
  -- Can persistent automatically do JSON? I think so.

  -- Return {searchId: int}
  -- Aeson Arrays are Haskell vectors
  return $ object ["places" .= (V.empty :: Array)]

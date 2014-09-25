module Handler.Places where

import Import
import Data.Aeson.Types
import Data.Maybe (catMaybes)
import Yesod.Auth
import qualified Data.Vector as V

-- Would the Maybe monad make this code cleaner?
getPlacesR :: SearchId -> Handler Value
getPlacesR searchId = do
    maid <- maybeAuthId
    case maid of
        Nothing ->
            notAuthenticated
        Just authId -> do
            -- Check that authId and searchId is in table.
            maybeAuthd <- runDB $ selectFirst [AuthorizedForUserId ==. authId,
                                               AuthorizedForSearchId ==. searchId]
                                              []
            case maybeAuthd of
                Nothing ->
                    permissionDenied "Not authorised for this search id."
                Just _  ->
                    authenticatedGetPlacesR searchId

authenticatedGetPlacesR :: SearchId -> Handler Value
authenticatedGetPlacesR searchId = do
  -- Get the corresponding row from the Id
  maybeSearchEntry <- runDB $ get searchId

  case maybeSearchEntry of
    Nothing -> return $
      object [ "error"  .= ("No such search with id" :: Text)
             , "places" .= (V.empty :: Array)
             ]

    Just searchEntry -> do
      -- Extract from people column of Searches table
      --     people :: [PeopleId]
      let placeIds = searchPlaces searchEntry

      -- Then get these entries from the People table,
      --  and output as JSON.

      -- [PeopleId] to [Maybe People],
      -- then [People] without the Nothing ones
      maybePlaces <- mapM (\pId -> runDB $ get pId) placeIds
      let places = catMaybes maybePlaces

          -- There's surely a better way than this?
          -- e.g. GHC Generics? Though the record is from TH.
          placeValues = map toJSON places

      -- Return {places: [{name, location {lat, lng}, yelpid, imgurl}]}
      -- Aeson Arrays are Haskell vectors
      return $ object ["places" .= V.fromList placeValues]

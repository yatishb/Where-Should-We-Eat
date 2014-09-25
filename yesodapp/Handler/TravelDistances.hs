module Handler.TravelDistances where

import Import
import Data.Aeson
import Data.Maybe
import Control.Monad.IO.Class (liftIO)

getTravelDistancesR :: SearchId -> String -> Handler Value
getTravelDistancesR searchId yelpId = do
	placeId <- runDB $ selectFirst [PlaceYelpid ==. yelpId] []
	
	case placeId of
		Just placeData -> do
		    let placeId = entityKey placeData
		        grabInt64 (PersistInt64 x) = x
		        placeIdNum = grabInt64 $ unKey placeId
		    liftIO $ print $ placeIdNum
		Nothing ->
		    -- No such place exists
		    liftIO $ print $ "No Data"
	--liftIO $ print $ entityKey $ fromMaybe placeId
	return $ object[]
	

module Handler.Chosen where

import Import
import Data.Aeson

getChosenR :: SearchId -> String -> Handler Value
getChosenR searchId yelpid = do
	-- Get PlaceId of place with yelpId
	maybePlaceId <- runDB $ selectFirst [PlaceYelpid ==. yelpid] []
	
	case maybePlaceId of
		Nothing -> return $ 
			object []

		Just placeId -> do
			let placeIdKey = entityKey placeId
			--let modify = entityKey Just maybePlaceId
			runDB $ update searchId [SearchChosen =. Just placeIdKey]
			return $ object[]

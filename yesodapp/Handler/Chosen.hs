{-# LANGUAGE DeriveGeneric #-}
module Handler.Chosen where

import Import
import Data.Aeson
import Data.Maybe
import GHC.Generics
import Data.Attoparsec.Number
import qualified Data.Text as T
import qualified Data.HashMap.Strict as M
import qualified Data.ByteString.Lazy as L
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC8

-- Pull a key out of an JSON object.
(^?) :: Value -> T.Text -> Maybe Value
(^?) (Object obj) k = M.lookup k obj
(^?) _ _ = Nothing

toString :: Value -> String
toString v@(String val) = T.unpack val

getChosenR :: SearchId -> Handler Value
getChosenR searchId = do
	maybeSearchId <- runDB $ get searchId
	case maybeSearchId of
		Nothing -> return $
			object[ "error" .= ("No search found" :: String)]
		Just searchTuple -> do
			let placeid = searchChosen searchTuple

			case placeid of
				Nothing -> return $ object ["error" .= ("No place chosen" :: String)]
				
				Just chosenPlaceId -> do
					maybePlaceId <- runDB $ get chosenPlaceId
					case maybePlaceId of
						Nothing -> return $
							object[ "error" .= ("No place found" :: String)]
						Just placeId -> do
							let yelpid = placeYelpid placeId
							return $ object[ "place" .= yelpid]


postChosenR :: SearchId -> Handler Value
postChosenR searchId = do
    inputJSON <- requireJsonBody
    let yId = toString ( fromMaybe "Chosen: No YelpID" $ inputJSON ^? "yelpid" )


    -- Get PlaceId of place with yelpId
    maybePlaceId <- runDB $ selectFirst [PlaceYelpid ==. yId] []
    
    case maybePlaceId of
        Nothing -> return $ 
            object []

        Just placeId -> do
            let placeIdKey = entityKey placeId
            runDB $ update searchId [SearchChosen =. Just placeIdKey]
            return $ object[]

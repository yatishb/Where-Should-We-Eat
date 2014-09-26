module Handler.TravelDistances where

import Import
import Data.Aeson
import Data.Maybe
import qualified Data.Vector as V

createObject name distance = do
	return $ object [ "name" .= name
					, "distance" .= distance
					]

getTravelDistancesR :: SearchId -> String -> Handler Value
getTravelDistancesR searchId yelpId = do
	-- Get PlaceId to search for distances in SearchPlaces
	placeId <- runDB $ selectFirst [PlaceYelpid ==. yelpId] []
	
	case placeId of
		Nothing -> return $ 
			object [ "error"  .= ("No such yelpid" :: Text)
                   , "places" .= (V.empty :: Array)
                   ]

		Just placeData -> do
		    let placeIdKey = entityKey placeData
			-- Get all people involved in a search
		    peopleSearch <- runDB $ get searchId

		    case peopleSearch of
		    	Nothing -> return $ 
		    		object [ "error"  .= ("No such search with id" :: Text)
                           , "places" .= (V.empty :: Array)
                           ]

		    	Just searchData -> do
		    		-- Get peopleIDs involved in search
		    		let people = searchPeople searchData
		    		-- Get names of people from their IDs
		    		peopleTuples <- mapM (\pid -> runDB $ get pid) people
		    		let names = map personName $ catMaybes peopleTuples

		    		-- Get Distances from SearchPlaces
		    		distanceTuple <- runDB $ selectFirst [SearchPlaceSearchid ==. searchId, SearchPlacePlaceid ==. placeIdKey] []

		    		case distanceTuple of
		    			Nothing -> return $ 
		    				object [ "error"  .= ("No such search and place" :: Text)
		    				       , "places" .= (V.empty :: Array)
		    				       ]

		    			Just distanceTupleData -> do
		    				let value = entityVal distanceTupleData
		    				let distances = searchPlaceDistance value
		    				finalObject <- mapM (\(n, d) -> createObject n d) $ zip names distances
		    				return $ object[ "distances" .= finalObject]

module Handler.TravelDistances where

import Import
import Data.Aeson
import Data.Maybe
import qualified Data.Vector as V
import Distances

createObject name distance = do
	return $ object [ "name" .= name
					, "distance" .= distance
					]


-- Compute Distances for all places in a particular search
computeDistancesInSearch :: SearchId -> Handler Value
computeDistancesInSearch searchId = do
	-- TO GET DISTANCE & INSERT INTO SEARCHPLACE TABLE
	searchTuple <- runDB $ get searchId

	case searchTuple of
		Nothing -> return $ object[]
		Just searchedTuple -> do
			let placeIds = searchPlaces searchedTuple
			    peopleIds = searchPeople searchedTuple

			inputPeople <- mapM (\x -> runDB $ get x) peopleIds

			-- Extract all destination locations
			let grabInt64 (PersistInt64 x) = x
			    placeNumbers = map (\x -> grabInt64 $ unKey x) placeIds
			maybePlaceLocs <- mapM (\p -> runDB $ get p) placeIds
			let placeLocs = map placeLocation $ catMaybes maybePlaceLocs
			--Extract all origin locations
			    originLocs = map personLocation $ catMaybes inputPeople
			-- Get all distance. Retrieves array of arrays
			allDistances <- mapM (\d -> getDistancesOriginListToDestination originLocs d) placeLocs
			--Insert into SearchPlace table
			let input1 = zip placeIds allDistances
			mapM_ (\(p,d) -> runDB $ insert $ SearchPlace searchId p d) input1
			return $ object[]



readTravelDistancesFromDB :: SearchId -> PlaceId -> Handler Value
readTravelDistancesFromDB searchId placeIdKey = do
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




getTravelDistancesR :: SearchId -> String -> Handler Value
getTravelDistancesR searchId yelpId = do
	-- Check if exists in searchPlace table.
	-- If not then calculate distances
	-- Both cases call read func

	-- Get PlaceId to search for distances in SearchPlaces
		placeId <- runDB $ selectFirst [PlaceYelpid ==. yelpId] []
		
		case placeId of
			Nothing -> return $ 
				object [ "error"  .= ("No such yelpid" :: Text)
	                   , "places" .= (V.empty :: Array)
	                   ]

			Just placeData -> do
				let placeIdKey = entityKey placeData
				distanceTuple <- runDB $ selectFirst [SearchPlaceSearchid ==. searchId, SearchPlacePlaceid ==. placeIdKey] []

				case distanceTuple of
					Nothing -> do
						computeDistancesInSearch searchId
						readTravelDistancesFromDB searchId placeIdKey
					Just distanceTupleData -> do
						readTravelDistancesFromDB searchId placeIdKey

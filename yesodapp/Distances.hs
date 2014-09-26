{-# LANGUAGE OverloadedStrings #-}
module Distances where

import Import
import JSONUtils
import Control.Monad.IO.Class
import Network.HTTP.Conduit
import Location
import Data.Maybe
import Data.Aeson
import Data.Vector((!?))
import qualified Data.List as DL
import qualified Data.Vector as V
import qualified Data.Text as T
import qualified Data.HashMap.Strict as M
import qualified Data.ByteString.Lazy as L
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC8

googleapikey = "AIzaSyC3gDIDBRQydVIE4hLe6IzRUrBX-OlgRY8"
googleapihost = "https://maps.googleapis.com/maps/api"
distancematrixpath = "/distancematrix/json?"
origins = "origins="
destinations = "destinations="
locationapiseparator = "|"

-- Extract out the distance value from the element json
extractDistances :: MonadIO m => Value -> m Int
extractDistances rowObject = do
    let element = fromJust $ ix (fromMaybe "empty row" $ rowObject ^? "elements") 0
        distance = fromMaybe "no distance element element" $ element ^? "distance"
        distvalue = toInt ( fromMaybe "no distance value" $ distance ^? "value" )
    return distvalue

-- Convert Location to a string where latitude and longitude are separated by comma
convertLocToString :: Location -> String
convertLocToString loc = do
	let clat = show $ lat loc
	    clng = show $ lng loc
	locString <- clat ++ "," ++ clng
	return locString

-- Build the search url for the google distance matrix using array of origin locations and destination loc
buildUrl :: [Location]-> Location -> String
buildUrl originLocs destLoc = do 
	let urlHeader = googleapihost ++ distancematrixpath ++ origins
	    origLocString = concat( DL.intersperse locationapiseparator $ map convertLocToString originLocs )
	    destLocString = convertLocToString destLoc
	    urlDest = "&" ++ destinations ++ destLocString
	    urlKey = "&key=" ++ googleapikey
	url <- urlHeader ++ origLocString ++ urlDest ++ urlKey
	return url


-- Retrieve array of distances of the destination from each of the origins
getDistancesOriginListToDestination :: MonadIO m => [Location] -> Location -> m [Int]
getDistancesOriginListToDestination originLocs destLoc = do
	let url = buildUrl originLocs destLoc
	res <- simpleHttp url
	let decoded = fromJust $ decode res
	    rows = fromJust $ decoded ^? "rows"
	distances <- case rows of
                    (Array rowVec) -> mapM extractDistances $ V.toList rowVec
	return distances

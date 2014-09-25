module Handler.GeoCode where

import Network.HTTP.Conduit
import qualified Data.ByteString.Lazy as L
-- import Network (withSocketsDo)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC8

import Data.Aeson
import Data.Aeson.Types
import Data.Attoparsec.Number
import Data.Maybe (fromJust, Maybe, fromMaybe)
import Data.Vector ((!?))                 -- requires vector
import qualified Data.Text as T
import qualified Data.HashMap.Strict as M -- requires unordered-containers

import qualified Location as Loc

import Import

-- From the fantastic http://dev.stephendiehl.com/hask/
-- Pull a key out of an JSON object.
(^?) :: Value -> T.Text -> Maybe Value
(^?) (Object obj) k = M.lookup k obj
(^?) _ _ = Nothing

-- Pull the ith value out of a JSON list.
ix :: Value -> Int -> Maybe Value
ix (Array arr) i = arr !? i
ix _ _ = Nothing

-- Not sure how dangerous this is,
-- but pattern-match to coerce Value to (Number n)
-- Converting to Text / read, just feels dirty,
-- but I couldn't figure out Number -> Double.
toDouble :: Value -> Double
toDouble v@(Number val) = read valStr
  where
    valStr = BC8.unpack $ BS.pack $ L.unpack $ encode v

getGoogleResult postCode = "http://maps.google.com/maps/api/geocode/json?address=" ++ postCode ++",+SG"

geocode :: MonadIO m => String -> m Loc.Location
geocode postalCode = do
  let addr = postalCode
  bsResult <- simpleHttp (getGoogleResult addr)
  let result =   fromMaybe (error "GeoCode: bad decode") $ decode bsResult
      results  = fromMaybe (error "GeoCode: no 'results' property.") $ result ^? "results"
      geometry = fromMaybe (error "GeoCode: 'geometry' of entry 0") $
                   (fromMaybe (error $ "GeoCode: No results for" ++ addr) $
                              ix results 0) ^? "geometry"
      location = fromMaybe (error "GeoCode: No 'location' property.") $ geometry ^? "location"

  return Loc.Location
         { Loc.lat = toDouble (fromJust $ location ^? "lat")
         , Loc.lng = toDouble (fromJust $ location ^? "lng")
         }


getGeoCodeR :: String -> Handler Value
getGeoCodeR postalCode = do
  location <- geocode postalCode
  return $ toJSON location -- {"lat": .., "lng": ..}

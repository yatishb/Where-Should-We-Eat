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

import JSONUtils
import Import

getGoogleResult postCode = "http://maps.google.com/maps/api/geocode/json?address=" ++ postCode ++"&components=country:SG"

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

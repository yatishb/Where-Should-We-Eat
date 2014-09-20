module Handler.GeoCode where

import Network.HTTP.Conduit
import qualified Data.ByteString.Lazy as L
-- import Network (withSocketsDo)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC8

import Data.Aeson
import Data.Aeson.Types
import Data.Maybe (fromJust, Maybe)
import Data.Vector ((!?))                 -- requires vector
import qualified Data.Text as T
import qualified Data.HashMap.Strict as M -- requires unordered-containers

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

getGoogleResult postCode = "http://maps.google.com/maps/api/geocode/json?address=" ++ postCode ++",+SG"

getGeoCodeR :: String -> Handler Value
getGeoCodeR postalCode = do
  bsResult <- simpleHttp (getGoogleResult postalCode)
  let result =   fromJust $ decode bsResult
  let results  = fromJust $ result ^? "results"
  let geometry = fromJust $ (fromJust $ ix results 0) ^? "geometry"
  let location = fromJust $ geometry ^? "location"
  return location -- {"lat": .., "lng": ..}

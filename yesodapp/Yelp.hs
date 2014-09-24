{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric #-}
module Yelp where

import Control.Monad.IO.Class  (liftIO)
import Data.Maybe
import Network.OAuth.Consumer
import Network.OAuth.Http.Request
import Network.OAuth.Http.Response
import Network.OAuth.Http.HttpClient
import Network.OAuth.Http.CurlHttpClient
import Network.Curl
import Network.HTTP.Base
import qualified Data.ByteString.Lazy as L
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC8
import Location
import GHC.Generics
import Data.Aeson
import Data.Vector ((!?))
import qualified Data.Vector as V
import qualified Data.Text as T
import qualified Data.HashMap.Strict as M
import Import
import qualified Handler.GeoCode as G


-- Yelp Credential Details
token = "frU8c4V-6t_S6eZyoMZpJ764FZb94hEh"
tokensecret = "y7t8tKBt1RhQ44wuSsWfJgSVofE"
consumerkey = "9Lgn7iq0ngyyXHqv4I6QUA"
consumersecret = "JbrkdEAAAyxY6wlssItawSxB5Ac"

apihost = "http://api.yelp.com"
searchpath = "/v2/search/"
businesspath = "/v2/business/"


data Consumer = Consumer
    { key :: String
    , secret :: String }
    deriving (Show, Eq)

yelpRequest path urlparam = do
    {-
    Arguments : path (whether need to use search api or business api)
                urlparam (values which need to be used to perform the api request with)
    Returns : ByteString of the response of the api call
    -}
    --let urlparam = "term=food&cll=1.291766,103.782848"
    let queryUrl = apihost ++ path ++ "?" ++ urlparam
    -- Use the consumer key and secret and generate the 2 legged token
        appConsumer = Application consumerkey consumersecret OOB
        tokenConsumer = fromApplication appConsumer
    -- Generate user access token
        tokenUser = [("oauth_token", token)
                   ,("oauth_token_secret", tokensecret)]
        actualTokenUser = AccessToken appConsumer (fromList tokenUser `union` oauthParams tokenConsumer)
    -- Create service request using the queryUrl, default GET req
        serviceReq = fromJust $ parseURL queryUrl
    -- Get the response for the query
    -- Using the three-legged oauth process : consumer token(2 legged token), user access token, signature method and url
    res <- runOAuthM tokenConsumer $ signRq actualTokenUser HMACSHA1 (Just $ Realm "realm") serviceReq >>= serviceRequest CurlClient
    return $ rspPayload res



-- From the fantastic http://dev.stephendiehl.com/hask/
-- Pull a key out of an JSON object.
(^?) :: Value -> T.Text -> Maybe Value
(^?) (Object obj) k = M.lookup k obj
(^?) _ _ = Nothing

toDouble :: Value -> Double
toDouble v@(Number val) = read valStr
  where
    valStr = BC8.unpack $ BS.pack $ L.unpack $ encode v

toString :: Value -> String
toString v@(String val) = T.unpack val

concatenate v@(Array val) = concat $ map toString $ V.toList val


{-data Place = Place
             { yelpname :: String
             , location :: Location
             , yelpid :: String
             , imgurl :: String
             } deriving (Show, Read, Eq, Generic) -}

extractplace :: MonadIO m => Value -> m Place
extractplace placeObject = do
    {-
    Arguments : Object of the business
    Returns : return the business as a place
    -}
    let name = toString ( fromMaybe (error "no name found") $ placeObject ^? "name" )
        yelpid = toString ( fromMaybe (error "no yelpid found") $ placeObject ^? "id" )
        imgurl = toString ( fromMaybe "noimage" $ placeObject ^? "image_url" )
        address = urlEncode( concatenate (fromMaybe (error "no address found") $ (fromMaybe (error "no location found") $ placeObject ^? "location") ^? "address" ) )
    loc <- G.geocode address
    let place = Place name loc yelpid imgurl

    return place


search :: MonadIO m => Location -> m [Place]
search location = do
    {-
    Arguments : location of the area near which the search is to be performed
    Returns : return list of places
    -}
    let clat = show $ lat location
        clng = show $ lng location
    let searchparam = "term=food&ll=" ++ clat ++ "%2C" ++ clng ++ "&sort=1"
    -- Search yelp with required parameters
    response <- yelpRequest searchpath searchparam
    -- Decode the received result and create list of Places
    let decoded = fromMaybe (error "no response found") $ decode response
    let businesses = fromMaybe (error "no businesses found") $ decoded ^? "businesses"
    -- Create [Place] from the businesses with only the necessary info
    places <- case businesses of
                    (Array busVec) -> mapM extractplace $ V.toList busVec
        
    return places


business yelpid = do
    {-
    Arguments : postalcode of the area near which the search is to be performed
    Returns :
    -}
    return ()

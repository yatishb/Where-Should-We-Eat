{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric #-}

module Location where

import Database.Persist.TH
import GHC.Generics
import Data.Aeson
-- I don't understand why this is necessary. What is supressing Prelude?
import Prelude (Show, Read, Eq, Double, map, sum, (/), fromIntegral, length)

-- These names are quite awful,
-- So maybe import Location qualified only
-- Also, doesn't derive Show
data Location = Location
                { lat :: Double
                , lng :: Double
                } deriving (Show, Read, Eq, Generic)

derivePersistField "Location"

instance ToJSON Location
instance FromJSON Location

averageLocation :: [Location] -> Location
averageLocation locations =
  Location { lat = avg lats, lng = avg lngs}
    where
  avg xs = (sum xs) / fromIntegral (length xs)
  lats   = map lat locations
  lngs   = map lng locations

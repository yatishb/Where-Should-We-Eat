{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric #-}

module Location where

import Database.Persist.TH
import GHC.Generics
import Data.Aeson
import Prelude (Show, Read, Eq, Double)

-- These names are quite awful,
-- So maybe import Location qualified only
-- Also, doesn't derive Show
data Location = Location
                { lat :: Double
                , lng :: Double
                } deriving (Show, Read, Eq, Generic)

instance ToJSON Location
instance FromJSON Location

derivePersistField "Location"

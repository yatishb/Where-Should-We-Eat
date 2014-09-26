module JSONUtils where

import Import
import Data.Aeson
import Data.Vector ((!?))
import qualified Data.HashMap.Strict as M
import qualified Data.Text as T
import qualified Data.Vector as V
import qualified Data.ByteString.Lazy as L
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC8

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

toInt :: Value -> Int
toInt v@(Number val) = read valStr
  where
    valStr = BC8.unpack $ BS.pack $ L.unpack $ encode v

toString :: Value -> String
toString v@(String val) = T.unpack val

concatenate :: Value -> String
concatenate v@(Array val) = concat $ map toString $ V.toList val

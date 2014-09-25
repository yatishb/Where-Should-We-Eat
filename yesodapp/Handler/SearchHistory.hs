module Handler.SearchHistory where

import Import
import Data.Aeson
import Data.Aeson.Types
import Data.Attoparsec.Number
import Data.Maybe (catMaybes)
import Yesod.Auth
import qualified Data.Vector as V

getSearchHistoryR :: Handler Value
getSearchHistoryR = do
    maid <- maybeAuthId
    case maid of
        Nothing ->
            notAuthenticated
        Just authId -> do
            authenticatedGetSearchHistoryR authId


authenticatedGetSearchHistoryR :: UserId -> Handler Value
authenticatedGetSearchHistoryR authId = do
    -- Lookup in the DB, finding all the rows with authId
    entityList <- runDB $ selectList [AuthorizedForUserId ==. authId] []

    let authdSearchIds = map (\x -> authorizedForSearchId $ entityVal x) entityList

        -- PersistInt64, which is a PersistValue
        searchIdToNumber sid = Number $ fromIntegral sidInt64
            where
            sidInt64 = grabInt64 keyPersistValue
            grabInt64 (PersistInt64 x) = x
            keyPersistValue = unKey sid

        authdSearchNumbers = map searchIdToNumber authdSearchIds

    -- return $ object ["searchIds" .= (fromIntegral keyInt64 :: Number)]
    return $ object ["searchIds" .= (V.fromList authdSearchNumbers :: Array)]

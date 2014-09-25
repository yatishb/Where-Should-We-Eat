module Handler.IsAuthorized where

import Import
import Data.Aeson
import Yesod.Auth
import Yesod.Auth.GoogleEmail

isLoggedIn = do
    mu <- maybeAuthId
    return $ case mu of
        Nothing -> False
        Just _  -> True

getIsAuthorizedR :: Handler Value
getIsAuthorizedR = do
    loggedIn <- isLoggedIn
    return $ object ["isloggedin" .= (loggedIn :: Bool)]

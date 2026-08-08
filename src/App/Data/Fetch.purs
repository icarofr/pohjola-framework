-- | Shared data-fetching boundary. Every feature Service module fetches
-- | through here. Feature modules must NEVER import another feature's
-- | modules (enforced by ContractSpec).
module App.Data.Fetch (fetchJson, statusToAppError) where

import Prelude

import App.Error (AppError(..))
import App.FetchBun (fetchImpl)
import Data.Argonaut.Decode (class DecodeJson, decodeJson)
import Data.Argonaut.Decode.Error (JsonDecodeError(..))
import Data.Argonaut.Parser (jsonParser)
import Data.Bifunctor (lmap)
import Data.Either (Either(..))
import Effect.Aff (Aff, Canceler(..), makeAff)
import Effect.Class (liftEffect)

-- | Fetch JSON from a URL and decode via Argonaut.
-- | Shared by all data-backed features — the single boundary where
-- | fetch errors and decode errors are mapped to AppError.
-- | Uses Bun's native fetch (not Affjax.Node) so it works in forked
-- | fibers — enabling streaming SSR. The AbortController canceler
-- | ensures killed fibers abort the in-flight request.
statusToAppError :: Int -> Either AppError Unit
statusToAppError code | code >= 200 && code < 300 = Right unit
statusToAppError 404 = Left NotFound
statusToAppError code = Left (HttpStatusError code)

fetchJson :: forall a. DecodeJson a => String -> Aff (Either AppError a)
fetchJson url = do
  result <- makeAff \callback -> do
    cancel <- fetchImpl url "GET" [] ""
      (\res -> callback (Right (Right res)))
      (\msg -> callback (Right (Left msg)))
    pure (Canceler \_ -> liftEffect cancel)
  pure case result of
    Left msg -> Left (HttpError msg)
    Right { status, body } ->
      case statusToAppError status of
        Left err -> Left err
        Right _ -> case jsonParser body of
          Left parseErr -> Left (DecodeError (TypeMismatch parseErr))
          Right json -> lmap DecodeError (decodeJson json)

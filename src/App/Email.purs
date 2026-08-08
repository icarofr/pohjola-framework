-- | Resend email API wrapper using Bun's native fetch (no Affjax).
-- |
-- | Errors as values: returns `Either AppError Unit`, not exceptions.
-- | JSON at the boundary (Argonaut for type-safe JSON construction).
-- | Form parsing via Data.FormURLEncoded (idiomatic PS, direct dependency).
module App.Email where

import Prelude

import App.Error (AppError(..))
import App.FetchBun (fetchImpl)
import App.Form (toMap)
import Data.Argonaut.Core (Json, fromObject, fromString, stringify)
import Data.Either (Either(..))
import Data.FormURLEncoded (decode)
import Data.Map as Map
import Foreign.Object as Object
import Data.Maybe (Maybe)
import Data.Tuple (Tuple(..))
import Effect.Aff (Aff, Canceler(..), makeAff)
import Effect.Class (liftEffect)

-- ============================================================================
-- Form body parsing (application/x-www-form-urlencoded)
-- ============================================================================

-- | Parse a form-encoded body, returning the value for a key.
-- | Uses Data.FormURLEncoded.decode (handles + as spaces, %3D as =, etc.)
parseForm :: String -> String -> Maybe String
parseForm body key = do
  form <- decode body
  let m = toMap form
  Map.lookup key m

-- ============================================================================
-- JSON building (Argonaut — type-safe)
-- ============================================================================

jsonFromPairs :: Array (Tuple String String) -> Json
jsonFromPairs pairs =
  fromObject $ Object.fromFoldable $ map (\(Tuple k v) -> Tuple k (fromString v)) pairs

-- ============================================================================
-- Resend API
-- ============================================================================

resendUrl :: String
resendUrl = "https://api.resend.com/emails"

-- | Send an email via Resend. Shared by contact and newsletter.
-- | The apiKey gate is in Config (Maybe String) — callers never pass "".
-- | 2xx = delivered; anything else (401 fake key, 422, 500) is a ResendError.
sendResend :: String -> Json -> Aff (Either AppError Unit)
sendResend apiKey body = do
  result <- makeAff \callback -> do
    cancel <- fetchImpl resendUrl "POST"
      [ Tuple "Authorization" ("Bearer " <> apiKey)
      , Tuple "Content-Type" "application/json"
      ]
      (stringify body)
      (\res -> callback (Right (Right res)))
      (\msg -> callback (Right (Left msg)))
    pure (Canceler \_ -> liftEffect cancel)
  pure case result of
    Left msg -> Left (HttpError msg)
    Right { status } ->
      if status >= 200 && status < 300 then Right unit
      else Left (ResendError status)

-- | Resend config slice — passed as a record to avoid 6 positional args.
type ResendConfig = { apiKey :: String, from :: String, to :: String }

-- | Send a contact form email via Resend.
sendContactEmail :: ResendConfig -> { name :: String, email :: String, message :: String } -> Aff (Either AppError Unit)
sendContactEmail cfg msg =
  sendResend cfg.apiKey $ jsonFromPairs
    [ Tuple "from" cfg.from
    , Tuple "to" cfg.to
    , Tuple "reply_to" msg.email
    , Tuple "subject" ("Contact form — " <> msg.name)
    , Tuple "text"
        ( "Name: " <> msg.name <> "\n"
            <> "Email: "
            <> msg.email
            <> "\n"
            <> "\n"
            <> msg.message
        )
    ]

-- | Send a newsletter signup notification via Resend.
sendNewsletterEmail :: ResendConfig -> String -> Aff (Either AppError Unit)
sendNewsletterEmail cfg subscriberEmail =
  sendResend cfg.apiKey $ jsonFromPairs
    [ Tuple "from" cfg.from
    , Tuple "to" cfg.to
    , Tuple "subject" "New newsletter subscriber"
    , Tuple "text" ("New subscriber: " <> subscriberEmail)
    ]

-- | Application error sum type.
-- |
-- | Idiomatic Haskell/PS: errors as values, not exceptions. Every boundary
-- | function (HTTP, FFI) returns `Aff (Either AppError a)`. Callers must
-- | pattern-match exhaustively — adding a variant breaks all handlers at
-- | compile time.
module App.Error where

import Prelude

import Data.Argonaut.Decode.Error (JsonDecodeError)

-- | The single error type for the application.
-- | Add variants as needed — the compiler will tell you every handler
-- | that needs updating.
data AppError
  = DecodeError JsonDecodeError
  | HttpError String
  | HttpStatusError Int
  | FfiError String
  | NotFound
  | ResendError Int

instance showAppError :: Show AppError where
  show = case _ of
    DecodeError e -> "DecodeError: " <> show e
    HttpError msg -> "HttpError: " <> msg
    HttpStatusError code -> "HttpStatusError: " <> show code
    FfiError msg -> "FfiError: " <> msg
    NotFound -> "NotFound"
    ResendError status -> "ResendError: " <> show status

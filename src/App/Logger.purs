-- | Structured JSON logging — one line per event, always the same key
-- | order: ts, level, msg, then caller-provided fields in array order.
-- |
-- | Parseable by any log aggregator; grep-able by request id (`rid`).
-- | The pure `renderLogLine` is the seam under unit test; `log` is its
-- | Effect wrapper that stamps the current time.
module App.Logger
  ( Level(..)
  , levelString
  , renderLogLine
  , log
  , logInfo
  , logWarn
  , logErr
  ) where

import Prelude

import Data.Argonaut.Core (Json, fromString, fromObject, stringify)
import Data.Foldable (foldl)
import Data.JSDate (now, toISOString)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Exception as Exception
import Effect.Console as Console
import Foreign.Object (Object)
import Foreign.Object as Object

data Level = Info | Warn | Err

levelString :: Level -> String
levelString Info = "info"
levelString Warn = "warn"
levelString Err = "error"

-- | Pure JSON log line. Argonaut's string encoding handles escaping
-- | (quotes, backslashes, control chars). foreign-object preserves
-- | insertion order of string keys, so the output shape is deterministic:
-- | ts, level, msg, then fields in the order given.
renderLogLine :: Level -> String -> Array (Tuple String String) -> String -> String
renderLogLine lvl msg fields ts =
  let
    base :: Object Json
    base = Object.fromFoldable
      [ Tuple "ts" (fromString ts)
      , Tuple "level" (fromString (levelString lvl))
      , Tuple "msg" (fromString msg)
      ]
    withFields = foldl (\obj (Tuple k v) -> Object.insert k (fromString v) obj) base fields
  in
    stringify (fromObject withFields)

-- | Best-effort: logging must never crash the process (EPIPE when the
-- | collector pipe dies, stdout closed). Errors are swallowed here.
log :: Level -> String -> Array (Tuple String String) -> Effect Unit
log lvl msg fields = do
  ts <- toISOString =<< now
  void $ Exception.try (Console.log (renderLogLine lvl msg fields ts))

logInfo :: String -> Array (Tuple String String) -> Effect Unit
logInfo = log Info

logWarn :: String -> Array (Tuple String String) -> Effect Unit
logWarn = log Warn

logErr :: String -> Array (Tuple String String) -> Effect Unit
logErr = log Err

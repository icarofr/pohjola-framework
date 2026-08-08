-- | FFI bindings to Bun.serve — the tamed boundary (ADR-003, ADR-007).
-- |
-- | This module owns the `foreign import` declarations. The JS side
-- | (App.ServerBun.js) is plumbing only — no app logic. App.Server imports
-- | from here and wraps the untyped FFI in the typed Request/Response API.
module App.ServerBun where

import Prelude

import Data.Tuple (Tuple)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2)
import Foreign (Foreign)
import Foreign.Object (Object)

-- | Opaque ReadableStream — produced by streamResponseImpl, consumed by the FFI.
foreign import data ReadableStream :: Type

-- | Result of a fetch: HTTP status + response body text.
type FetchResult =
  { status :: Int
  , body :: String
  }

-- | Rendered content for a streaming route. The `html` field is the
-- | pre-rendered HTML string (content or error fragment) that the FFI
-- | enqueues into the ReadableStream.
type StreamContent =
  { html :: String
  }

-- | Raw JS request object produced by the FFI from the Web Request.
type RawRequest =
  { method :: String
  , url :: String
  , path :: String
  , query :: String
  , headers :: Object String
  , cookies :: Object String
  , ip :: String
  , body :: String
  }

-- | Raw JS response object PS returns to the FFI.
-- | bodyTag is "StringBody" or "StreamBody"; bodyStream is the ReadableStream
-- | (only meaningful when bodyTag === "StreamBody").
type RawResponse =
  { status :: Int
  , headers :: Array (Tuple String String)
  , bodyValue :: String
  , bodyTag :: String
  , bodyStream :: Foreign
  }

-- | Start Bun.serve. The callback receives the untyped request and a respond
-- | function; PS runs the handler in Aff and calls respond with the result.
foreign import serveImpl :: Int -> String -> EffectFn2 RawRequest (EffectFn1 RawResponse Unit) Unit -> Effect Unit

-- | Create a streaming ReadableStream for SSR. The stream is populated
-- | entirely in the JS event loop via async start + native fetch — no
-- | launchAff_, no makeAff, no Aff scheduler. PS provides synchronous
-- | rendering callbacks (pure functions):
--   - url: the API URL to fetch
--   - onContent: decodes JSON + renders HTML from the fetch result
--   - shellOpen/shellClose: pre-rendered HTML strings
foreign import streamResponseImpl
  :: String
  -> (FetchResult -> StreamContent)
  -> String
  -> String
  -> Effect ReadableStream

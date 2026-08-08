-- | FFI bindings to Bun's native fetch — the tamed boundary (ADR-007).
-- |
-- | Replaces Affjax.Node (node:http compat layer) which hangs in forked
-- | fibers on Bun. This module owns the `foreign import` declarations;
-- | the JS side (App.FetchBun.js) is plumbing only — no app logic.
module App.FetchBun where

import Prelude

import Data.Tuple (Tuple)
import Effect (Effect)

-- | Result of a fetch: HTTP status + response body text.
type FetchResult =
  { status :: Int
  , body :: String
  }

-- | Native fetch via Bun. Curried JS function returning Effect (Effect Unit).
-- | PS wraps this in Aff via Effect.Aff.Compat.makeAff for ergonomic use.
-- | The callbacks are `(FetchResult -> Effect Unit)` and `(String -> Effect Unit)`.
-- | The returned `Effect Unit` is a canceler that aborts the in-flight fetch
-- | via AbortController — wired into makeAff's Canceler so killed fibers
-- | don't leave dangling requests.
foreign import fetchImpl
  :: String
  -> String
  -> Array (Tuple String String)
  -> String
  -> (FetchResult -> Effect Unit)
  -> (String -> Effect Unit)
  -> Effect (Effect Unit)

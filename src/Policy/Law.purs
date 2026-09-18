-- | Named architectural laws — catalog inhabitants for docs/GUARANTEES.md.
-- |
-- | This module names which laws exist. `Policy.Contract` owns the scan-config
-- | lists; `Test.Policy.Scan` is the filesystem adapter. Adding a constructor
-- | without updating `catalogNeedle` is a compile error; a needle missing from
-- | the catalog fails `make gate`.
module Policy.Law
  ( Law(..)
  , allLaws
  , catalogNeedle
  ) where

import Prelude

data Law
  = NoPartialFunctions
  | NoUnsafeCoerce
  | FfiAllowlist
  | NoRawHtml
  | TypedHandlerErrors
  | ExhaustiveMatches
  | DictionaryComplete
  | ExceptionContainment
  | NoHungRequests
  | SecurityHeaders
  | PinnedCsp
  | DatastarSeamScan
  | DatastarClosedConstructors
  | HoneypotSemantics
  | FormDecodeTotal
  | RouteRoundTrip
  | HtmlEscaped
  | NoExternalScripts
  | LayoutShell
  | CiRunsAll
  | MutatingRouteCsrf

derive instance eqLaw :: Eq Law

allLaws :: Array Law
allLaws =
  [ NoPartialFunctions
  , NoUnsafeCoerce
  , FfiAllowlist
  , NoRawHtml
  , TypedHandlerErrors
  , ExhaustiveMatches
  , DictionaryComplete
  , ExceptionContainment
  , NoHungRequests
  , SecurityHeaders
  , PinnedCsp
  , DatastarSeamScan
  , DatastarClosedConstructors
  , HoneypotSemantics
  , FormDecodeTotal
  , RouteRoundTrip
  , HtmlEscaped
  , NoExternalScripts
  , LayoutShell
  , CiRunsAll
  , MutatingRouteCsrf
  ]

-- | Unique substring that must appear in docs/GUARANTEES.md. Exhaustive: a
-- | new Law without a needle does not compile.
catalogNeedle :: Law -> String
catalogNeedle = case _ of
  NoPartialFunctions -> "No partial functions"
  NoUnsafeCoerce -> "No `unsafeCoerce`"
  FfiAllowlist -> "No unapproved FFI"
  NoRawHtml -> "No general-purpose unescaped HTML"
  TypedHandlerErrors -> "Every handler failure is a typed value"
  ExhaustiveMatches -> "Exhaustive pattern matching"
  DictionaryComplete -> "Dictionary completeness"
  ExceptionContainment -> "Runtime exceptions (socket errors"
  NoHungRequests -> "No hung requests"
  SecurityHeaders -> "Security headers on every response"
  PinnedCsp -> "CSP is the pinned nonce-based policy"
  DatastarSeamScan -> "Datastar seams can't silently break"
  DatastarClosedConstructors -> "Browser JS cannot be hand-written"
  HoneypotSemantics -> "Honeypot semantics"
  FormDecodeTotal -> "Form decoding is total"
  RouteRoundTrip -> "Route round-trips"
  HtmlEscaped -> "Rendered HTML never contains unescaped"
  NoExternalScripts -> "No external scripts"
  LayoutShell -> "Every page flows through the layout shell"
  CiRunsAll -> "All of the above runs on every push"
  MutatingRouteCsrf -> "Mutating POST is origin-gated"

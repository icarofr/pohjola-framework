-- | FFI bindings to Bun native utilities — SIMD-accelerated escapeHTML
-- | and XML.stringify for sitemap generation.
-- |
-- | The PS side stays pure; the JS side is plumbing only (ADR-007).
module App.Bun where

import Prelude

import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)
import Foreign (Foreign)

-- | SIMD-accelerated HTML escaping via Bun.escapeHTML.
-- | Escapes & < > " ' — same set as App.Html.escape, but native.
-- | Note: Bun uses &#x27; for single quotes; PS escape used &#39;.
-- | Both are valid HTML5 entities.
foreign import escapeHTMLImpl :: String -> String

-- | Bun.XML.stringify — serializes a Bun.XML.Node tree to an XML string.
-- | The Node shape: { name: String, attributes: { [k]: String },
-- |   children: Array (Node | String) }
-- | Returns null on failure (lifted to Maybe via Data.Nullable).
foreign import stringifyXMLImpl :: Foreign -> Nullable String

-- | Safe wrapper: lifts the nullable FFI result to Maybe.
stringifyXML :: Foreign -> Maybe String
stringifyXML = toMaybe <<< stringifyXMLImpl

-- | HTML <head> rendering — meta, SEO, hreflang, CSS, dark mode init
module App.Layout.Head
  ( renderHead
  , seoDescription
  , ogLocale
  , renderJsonLd
  , escapeJson
  ) where

import Prelude

import App.Html (Html, attr, content_, el, href, name_, property_, rel_, text)
import App.Layout.Scripts (HeadScript(..), renderHeadScript)
import App.Layout.Styles (stylesCss)
import Data.Array (filter)
import Data.Content (siteInfo)
import Data.Foldable (foldMap)
import Data.I18n (Lang(..), defaultLang, langTag)
import Data.Maybe (Maybe(..))
import Data.Route (Route, allLangs, routeTitle, routeUrl)
import Data.String.Common (replaceAll) as S
import Data.String.Pattern (Pattern(..), Replacement(..))

renderHead :: String -> String -> Lang -> Route -> Html
renderHead baseUrl nonce lang route =
  -- Meta tags
  el "meta" [ attr "charset" "UTF-8" ] []
    <> el "meta" [ name_ "viewport", content_ "width=device-width, initial-scale=1.0" ] []
    <> el "meta" [ name_ "description", content_ (seoDescription lang route) ] []
    <> el "meta" [ name_ "author", content_ siteInfo.title ] []
    <> el "meta" [ name_ "theme-color", content_ siteInfo.themeColor ] []
    -- Pinned inline head scripts (closed HeadScript ADT per ADR-000)
    <> renderHeadScript nonce DarkModeInit
    <> renderHeadScript nonce TitleSync
    <> renderHeadScript nonce DevLiveReload
    -- Canonical
    <> el "link" [ rel_ "canonical", href (baseUrl <> routeUrl lang route) ] []
    -- hreflang alternates
    <> foldMap (hreflangTag baseUrl route) allLangs
    <> el "link" [ rel_ "alternate", attr "hreflang" "x-default", href (baseUrl <> routeUrl defaultLang route) ] []
    -- Favicon
    <> el "link" [ rel_ "icon", attr "type" "image/svg+xml", href "/favicon.svg" ] []
    -- Inlined CSS (eliminates render-blocking CSS network roundtrip)
    <> el "style" [] [ text (stylesCss <> "\n[x-cloak]{display:none!important}") ]
    -- Open Graph
    <> el "meta" [ property_ "og:type", content_ "website" ] []
    <> el "meta" [ property_ "og:title", content_ (routeTitle lang route) ] []
    <> el "meta" [ property_ "og:description", content_ (seoDescription lang route) ] []
    <> el "meta" [ property_ "og:url", content_ (baseUrl <> routeUrl lang route) ] []
    <> el "meta" [ property_ "og:site_name", content_ siteInfo.title ] []
    <> el "meta" [ property_ "og:locale", content_ (ogLocale lang) ] []
    <> foldMap (\l -> el "meta" [ property_ "og:locale:alternate", content_ (ogLocale l) ] []) (filter (_ /= lang) allLangs)
    -- Twitter
    <> el "meta" [ name_ "twitter:card", content_ "summary" ] []
    <> el "meta" [ name_ "twitter:title", content_ (routeTitle lang route) ] []
    <> el "meta" [ name_ "twitter:description", content_ (seoDescription lang route) ] []
    -- Title
    <> el "title" [] [ text (routeTitle lang route) ]
    -- JSON-LD structured data (exhaustive on Route, XSS-escaped)
    <> foldMap identity (renderJsonLd baseUrl nonce lang route)

hreflangTag :: String -> Route -> Lang -> Html
hreflangTag baseUrl route lang =
  el "link" [ rel_ "alternate", attr "hreflang" (langTag lang), href (baseUrl <> routeUrl lang route) ] []

ogLocale :: Lang -> String
ogLocale En = "en_US"
ogLocale Fr = "fr_FR"
ogLocale Pt = "pt_PT"

-- | `Route` is temporarily zero-constructor (clean-sheet rebuild, see
-- | .scratch/clean-sheet-homepage/) — unreachable body, kept total via the
-- | wildcard. Goes back to a named, exhaustive case over `dict.seo.*` as
-- | soon as a route exists to describe.
seoDescription :: Lang -> Route -> String
seoDescription _ route = case route of
  _ -> ""

-- ============================================================================
-- JSON-LD structured data — type-safe, exhaustive on Route, XSS-escaped
-- ============================================================================

-- | JSON-LD structured data for a route. Exhaustive on Route — each route
-- | type has its own schema. Returns Maybe because not every route has
-- | structured data.
-- |
-- | `Route` is temporarily zero-constructor (clean-sheet rebuild, see
-- | .scratch/clean-sheet-homepage/) — unreachable body, kept total via the
-- | wildcard. Goes back to a named, exhaustive case per route as soon as a
-- | route exists to describe.
renderJsonLd :: String -> String -> Lang -> Route -> Maybe Html
renderJsonLd _ _ _ route = case route of
  _ -> Nothing

-- | Escape < as \u003c (the JSON-LD XSS fix from Next.js's guide).
-- | Also escapes " and \ for valid JSON strings. Order matters:
-- | backslash first (so it doesn't double-escape backslashes introduced
-- | later), then ", then <.
escapeJson :: String -> String
escapeJson =
  S.replaceAll (Pattern "\\") (Replacement "\\\\")
    >>> S.replaceAll (Pattern "\"") (Replacement "\\\"")
    >>> S.replaceAll (Pattern "<") (Replacement "\\u003c")

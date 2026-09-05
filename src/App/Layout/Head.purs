-- | HTML <head> rendering — meta, SEO, hreflang, CSS, dark mode init
module App.Layout.Head
  ( renderHead
  , pageSyncAttrs
  , seoDescription
  , ogLocale
  , renderJsonLd
  , escapeJson
  ) where

import Prelude

import App.Html (Attr, Html, attr, content_, el, href, name_, property_, rel_, text)
import App.Layout.Scripts (HeadScript(..), renderHeadScript, renderJsonLdScript)
import App.Layout.Styles (stylesCss)
import Data.Argonaut.Core (Json, fromObject, fromString, stringify)
import Data.Array (filter)
import Data.Content (siteInfo)
import Data.Foldable (foldMap)
import Data.I18n (Lang(..), defaultLang, dict, langTag)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..), allLangs, routeTitle, routeUrl)
import Data.String.Common (joinWith, replaceAll) as S
import Data.String.Pattern (Pattern(..), Replacement(..))
import Data.Tuple (Tuple(..))
import Foreign.Object (Object)
import Foreign.Object as Object

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

pageSyncAttrs :: Lang -> Route -> Array Attr
pageSyncAttrs lang route =
  [ attr "data-page-description" (seoDescription lang route)
  , attr "data-page-og-locale" (ogLocale lang)
  , attr "data-page-og-alts" (S.joinWith "," (map ogLocale allLangs))
  ]
    <> [ attr "data-page-href-default" (routeUrl defaultLang route) ]
    <> map (\l -> attr ("data-page-href-" <> langTag l) (routeUrl l route)) allLangs

hreflangTag :: String -> Route -> Lang -> Html
hreflangTag baseUrl route lang =
  el "link" [ rel_ "alternate", attr "hreflang" (langTag lang), href (baseUrl <> routeUrl lang route) ] []

ogLocale :: Lang -> String
ogLocale En = "en_US"
ogLocale Fr = "fr_FR"
ogLocale Pt = "pt_PT"

seoDescription :: Lang -> Route -> String
seoDescription lang route =
  let
    d = dict lang
  in
    case route of
      Home -> d.seo.homeDescription
      About -> d.seo.aboutDescription
      Contact -> d.seo.contactDescription
      PostList -> d.seo.postsDescription
      PostDetail _ -> d.seo.postDetailDescription
      Fixtures -> d.seo.fixturesDescription

-- ============================================================================
-- JSON-LD structured data — type-safe, exhaustive on Route, XSS-escaped
-- ============================================================================

-- | JSON-LD structured data for a route. Exhaustive on Route — each route
-- | type has its own schema. Returns Maybe because not every route has
-- | structured data (About, Contact don't).
renderJsonLd :: String -> String -> Lang -> Route -> Maybe Html
renderJsonLd baseUrl nonce lang route = case route of
  Home -> Just $ jsonLdScript nonce
    [ Tuple "@context" "https://schema.org"
    , Tuple "@type" "WebSite"
    , Tuple "name" siteInfo.title
    , Tuple "url" baseUrl
    , Tuple "inLanguage" (langTag lang)
    ]
  PostList -> Just $ jsonLdScript nonce
    [ Tuple "@context" "https://schema.org"
    , Tuple "@type" "Blog"
    , Tuple "name" siteInfo.title
    , Tuple "url" (baseUrl <> routeUrl lang PostList)
    ]
  PostDetail _ -> Just $ jsonLdScript nonce
    [ Tuple "@context" "https://schema.org"
    , Tuple "@type" "BlogPosting"
    -- Placeholder — renderJsonLd receives Route, not the fetched Post.
    -- A real app would render JSON-LD after data fetch, outside renderHead.
    , Tuple "headline" "Blog Post"
    ]
  _ -> Nothing

-- | Render a JSON-LD <script> tag with XSS-safe escaping.
-- | Replaces < with \u003c to prevent </script> injection.
jsonLdScript :: String -> Array (Tuple String String) -> Html
jsonLdScript nonce pairs =
  let
    obj :: Object Json
    obj = Object.fromFoldable (map (\(Tuple k v) -> Tuple k (fromString (escapeJson v))) pairs)
    json = stringify (fromObject obj)
  in
    renderJsonLdScript nonce json

-- | Escape < as \u003c (the JSON-LD XSS fix from Next.js's guide).
-- | Also escapes " and \ for valid JSON strings. Order matters:
-- | backslash first (so it doesn't double-escape backslashes introduced
-- | later), then ", then <.
escapeJson :: String -> String
escapeJson =
  S.replaceAll (Pattern "\\") (Replacement "\\\\")
    >>> S.replaceAll (Pattern "\"") (Replacement "\\\"")
    >>> S.replaceAll (Pattern "<") (Replacement "\\u003c")

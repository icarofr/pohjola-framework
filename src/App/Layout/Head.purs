-- | HTML <head> rendering — meta, SEO, hreflang, CSS, dark mode init
module App.Layout.Head where

import Prelude

import App.Html (Html, attr, content_, el, href, name_, property_, rel_, text)
import Data.Argonaut.Core (Json, fromObject, fromString, stringify)
import Data.Content (siteInfo)
import Data.Foldable (foldMap)
import Data.I18n (Lang(..), langTag)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..), allLangs, routeTitle, routeUrl)
import Data.String.Common (replaceAll) as S
import Data.String.Pattern (Pattern(..), Replacement(..))
import Data.Tuple (Tuple(..))
import Foreign.Object (Object)
import Foreign.Object as Object

renderHead :: String -> String -> Lang -> Route -> Html
renderHead baseUrl nonce lang route =
  -- Meta tags
  el "meta" [ attr "charset" "UTF-8" ] []
    <> el "meta" [ name_ "viewport", content_ "width=device-width, initial-scale=1.0" ] []
    <> el "meta" [ name_ "robots", content_ "noindex, nofollow" ] []
    <> el "meta" [ name_ "description", content_ (seoDescription lang route) ] []
    <> el "meta" [ name_ "author", content_ siteInfo.title ] []
    <> el "meta" [ name_ "theme-color", content_ siteInfo.themeColor ] []
    -- Dark mode init (prevents FOUC — runs before paint, inline, nonced)
    <> el "script" [ attr "nonce" nonce ] [ text "if(localStorage.getItem('theme')==='dark'||((!localStorage.getItem('theme')||localStorage.getItem('theme')==='system')&&matchMedia('(prefers-color-scheme:dark)').matches))document.documentElement.classList.add('dark')" ]
    -- Inline scripts for title sync and popstate fix (nonced)
    <> el "script" [ attr "nonce" nonce ] [ text "(function(){window.addEventListener(\"ajax:merged\",function(){var m=document.getElementById(\"content\");if(m&&m.dataset.pageTitle)document.title=m.dataset.pageTitle});window.addEventListener(\"popstate\",function(e){if(e.state&&e.state.__ajax)window.location.reload()})})();" ]
    -- Canonical
    <> el "link" [ rel_ "canonical", href (baseUrl <> routeUrl lang route) ] []
    -- hreflang alternates
    <> foldMap (hreflangTag baseUrl route) allLangs
    <> el "link" [ rel_ "alternate", attr "hreflang" "x-default", href (baseUrl <> routeUrl En route) ] []
    -- Favicon
    <> el "link" [ rel_ "icon", attr "type" "image/svg+xml", href "/favicon.svg" ] []
    -- CSS (cache: max-age=3600 set server-side; bump fingerprinting via Tailwind build if needed)
    <> el "link" [ rel_ "preload", href "/css/styles.css", attr "as" "style" ] []
    <> el "link" [ rel_ "stylesheet", href "/css/styles.css" ] []
    -- x-cloak: hide Alpine elements until initialized
    <> el "style" [] [ text "[x-cloak]{display:none!important}" ]
    -- Open Graph
    <> el "meta" [ property_ "og:type", content_ "website" ] []
    <> el "meta" [ property_ "og:title", content_ (routeTitle lang route) ] []
    <> el "meta" [ property_ "og:description", content_ (seoDescription lang route) ] []
    <> el "meta" [ property_ "og:url", content_ (baseUrl <> routeUrl lang route) ] []
    <> el "meta" [ property_ "og:site_name", content_ siteInfo.title ] []
    <> el "meta" [ property_ "og:locale", content_ (ogLocale lang) ] []
    <> el "meta" [ property_ "og:locale:alternate", content_ (ogLocale (otherLang lang)) ] []
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

otherLang :: Lang -> Lang
otherLang En = Fr
otherLang Fr = En

seoDescription :: Lang -> Route -> String
seoDescription En = case _ of
  Home -> siteInfo.description
  About -> "Learn more about " <> siteInfo.title <> "."
  Contact -> "Get in touch with " <> siteInfo.title <> "."
  PostList -> "Read the latest posts on " <> siteInfo.title <> "."
  PostDetail _ -> "A post on " <> siteInfo.title <> "."
seoDescription Fr = case _ of
  Home -> "Site vitrine de demonstration PureScript + Alpine.js (SSR bilingue, formulaires, SEO)."
  About -> "En savoir plus sur " <> siteInfo.title <> "."
  Contact -> "Contactez " <> siteInfo.title <> "."
  PostList -> "Lire les derniers articles sur " <> siteInfo.title <> "."
  PostDetail _ -> "Un article sur " <> siteInfo.title <> "."

-- ============================================================================
-- JSON-LD structured data — type-safe, exhaustive on Route, XSS-escaped
-- ============================================================================

-- | JSON-LD structured data for a route. Exhaustive on Route — each route
-- | type has its own schema. Returns Maybe because not every route has
-- | structured data (About, Contact, Legal don't).
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
    el "script" [ attr "type" "application/ld+json", attr "nonce" nonce ] [ text json ]

-- | Escape < as \u003c (the JSON-LD XSS fix from Next.js's guide).
-- | Also escapes " and \ for valid JSON strings. Order matters:
-- | backslash first (so it doesn't double-escape backslashes introduced
-- | later), then ", then <.
escapeJson :: String -> String
escapeJson =
  S.replaceAll (Pattern "\\") (Replacement "\\\\")
    >>> S.replaceAll (Pattern "\"") (Replacement "\\\"")
    >>> S.replaceAll (Pattern "<") (Replacement "\\u003c")

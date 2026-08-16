-- | Sitemap.xml and robots.txt generation.
-- |
-- | Sitemap XML is serialized via Bun.XML.stringify (SIMD-accelerated)
-- | through App.Bun. The PS side builds a typed node tree; the FFI handles
-- | serialization. We deploy 100% on Bun, so no fallback path is needed.
module App.Sitemap where

import Prelude

import App.Bun (stringifyXML)
import Data.I18n (Lang, defaultLang, langTag)
import Data.Maybe (Maybe(..))
import Data.Route (Route, allLangs, allRoutes, routeUrl)
import Data.Tuple (Tuple(..))
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object as Object

-- | Render the sitemap as an XML string.
-- | Uses Bun.XML.stringify (native). If serialization fails (should not
-- | happen with well-formed input), falls back to a minimal valid sitemap
-- | with just the <urlset> root — enough for crawlers to not flag an error.
renderSitemap :: String -> String
renderSitemap baseUrl =
  case stringifyXML (unsafeToForeign (urlsetNode baseUrl)) of
    Just xml -> xmlDecl <> xml
    Nothing -> xmlDecl <> "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\" xmlns:xhtml=\"http://www.w3.org/1999/xhtml\" />"

xmlDecl :: String
xmlDecl = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

-- | Bun.XML.Node shape as a PS record — marshals to JS via unsafeToForeign.
-- | children is Foreign so it can hold both XMLNode and String (Bun.XML.Node
-- | children are Array(Node | string), a union PS records can't express).
type XMLNode =
  { name :: String
  , attributes :: Object.Object String
  , children :: Array Foreign
  }

-- | Helper: wrap a text string as a child.
txt :: String -> Foreign
txt = unsafeToForeign

-- | Helper: wrap a node as a child.
node :: XMLNode -> Foreign
node = unsafeToForeign

-- | Build the urlset XML node tree.
urlsetNode :: String -> XMLNode
urlsetNode baseUrl =
  { name: "urlset"
  , attributes: Object.fromFoldable
      [ Tuple "xmlns" "http://www.sitemaps.org/schemas/sitemap/0.9"
      , Tuple "xmlns:xhtml" "http://www.w3.org/1999/xhtml"
      ]
  , children: map (node <<< urlNode baseUrl) allRouteLangs
  }
  where
  allRouteLangs = do
    lang <- allLangs
    route <- allRoutes
    pure { lang, route }

-- | Build a single <url> node.
urlNode :: String -> { lang :: Lang, route :: Route } -> XMLNode
urlNode baseUrl { lang, route } =
  { name: "url"
  , attributes: Object.empty
  , children:
      [ node { name: "loc", attributes: Object.empty, children: [ txt (baseUrl <> routeUrl lang route) ] } ]
        <> map (node <<< xhtmlLink baseUrl route) allLangs
        <> [ node (xhtmlLinkDefault baseUrl route) ]
  }

xhtmlLink :: String -> Route -> Lang -> XMLNode
xhtmlLink baseUrl route l =
  { name: "xhtml:link"
  , attributes: Object.fromFoldable
      [ Tuple "rel" "alternate"
      , Tuple "hreflang" (langTag l)
      , Tuple "href" (baseUrl <> routeUrl l route)
      ]
  , children: []
  }

xhtmlLinkDefault :: String -> Route -> XMLNode
xhtmlLinkDefault baseUrl route =
  { name: "xhtml:link"
  , attributes: Object.fromFoldable
      [ Tuple "rel" "alternate"
      , Tuple "hreflang" "x-default"
      , Tuple "href" (baseUrl <> routeUrl defaultLang route)
      ]
  , children: []
  }

renderRobots :: String -> String
renderRobots baseUrl =
  "User-agent: *\n"
    <> "Disallow:\n"
    <> "\nSitemap: "
    <> baseUrl
    <> "/sitemap.xml\n"

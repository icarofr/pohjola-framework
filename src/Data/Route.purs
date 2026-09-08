-- | Route sum type with bidirectional routing via routing-duplex.
-- |
-- | One codec per language. `print` and `parse` both derive from the same
-- | codec — no duplicated path knowledge. Adding a constructor to `Route`
-- | but forgetting it in either codec = compile error (GRouteDuplex enforces
-- | the record row matches the Generic rep).
-- |
-- | This is the idiomatic PS solution to bidirectional routing, replacing
-- | hand-rolled parseRoute/routePath pairs where the parser's catch-all
-- | silently swallows forgotten routes.
module Data.Route where

import Prelude hiding ((/))

import Data.Array (concatMap, filter, head)
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.I18n (Lang(..), dict, parseLang)
import Data.I18n as I18n
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.String.Common (joinWith)
import Data.Tuple (Tuple(..))
import Routing.Duplex (RouteDuplex', int, parse, prefix, print, root, segment)
import Routing.Duplex.Generic as G
import Routing.Duplex.Generic.Syntax ((/))

-- ============================================================================
-- Route sum type
-- ============================================================================

data Route
  = Home
  | About
  | Contact
  | PostList
  | PostDetail Int
  | Fixtures

derive instance genericRoute :: Generic Route _
derive instance eqRoute :: Eq Route
derive instance ordRoute :: Ord Route

instance showRoute :: Show Route where
  show = case _ of
    Home -> "Home"
    About -> "About"
    Contact -> "Contact"
    PostList -> "PostList"
    PostDetail n -> "PostDetail " <> show n
    Fixtures -> "Fixtures"

-- ============================================================================
-- Bidirectional codec — one per language
-- ============================================================================

-- | Route codec for a given language. Print and parse derive from this.
-- | Adding a route constructor but forgetting it here = compile error.
routeCodec :: Lang -> RouteDuplex' Route
routeCodec En = root $ prefix "en" $ G.sum
  { "Home": G.noArgs
  , "About": "about" / G.noArgs
  , "Contact": "contact" / G.noArgs
  , "PostList": "posts" / G.noArgs
  , "PostDetail": "posts" / int segment
  , "Fixtures": "fixtures" / G.noArgs
  }
routeCodec Fr = root $ prefix "fr" $ G.sum
  { "Home": G.noArgs
  , "About": "a-propos" / G.noArgs
  , "Contact": "contact" / G.noArgs
  , "PostList": "articles" / G.noArgs
  , "PostDetail": "articles" / int segment
  , "Fixtures": "calendrier" / G.noArgs
  }
-- | Pt uses localized path segments under /pt.
routeCodec Pt = root $ prefix "pt" $ G.sum
  { "Home": G.noArgs
  , "About": "sobre" / G.noArgs
  , "Contact": "contato" / G.noArgs
  , "PostList": "artigos" / G.noArgs
  , "PostDetail": "artigos" / int segment
  , "Fixtures": "calendario" / G.noArgs
  }

-- ============================================================================
-- URL generation (derived from codec)
-- ============================================================================

-- | Full URL path: /en/about, /fr/a-propos
routeUrl :: Lang -> Route -> String
routeUrl lang = print (routeCodec lang)

-- | Per-route facts that used to be independent exhaustive dispatches
-- | scattered across this module and App.Main — static-vs-dynamic caching
-- | and prefetch targets. Both `App.Main.handleRoute` and `fragmentHtml`
-- | previously re-decided the static/dynamic split with their own 6-armed
-- | `case route of`; a route landing in the wrong branch of one but not the
-- | other compiled cleanly and silently misrouted caching. Deriving
-- | `isStaticRoute`/`staticRoutes` and both call sites from this one table
-- | closes that: there is now exactly one place to get it wrong.
type RouteMeta =
  { isStatic :: Boolean
  , prefetch :: Array Route
  }

-- | Exhaustive on Route — adding a constructor forces both a caching and a
-- | prefetch decision here, in one place, instead of two.
routeMeta :: Route -> RouteMeta
routeMeta = case _ of
  Home -> { isStatic: true, prefetch: [ PostList, About, Contact ] }
  About -> { isStatic: true, prefetch: [ Home, Contact ] }
  Contact -> { isStatic: true, prefetch: [ Home, About ] }
  Fixtures -> { isStatic: true, prefetch: [ Home ] }
  PostList -> { isStatic: false, prefetch: [ PostDetail 1, PostDetail 2 ] } -- Demo IDs matching JSONPlaceholder API; update for real CMS
  PostDetail _ -> { isStatic: false, prefetch: [ PostList ] }

-- | `renderPrefetch` emits `<link rel="prefetch">` for these routes, using the
-- | FULL page URL — not a fragment URL. A fragment entry could never be hit,
-- | because an Alpine click fetches the plain href with the `x-alpine-request`
-- | header. See `App.Layout.Page.renderPrefetch`, which previously said the
-- | opposite of this comment.
prefetchFor :: Route -> Array Route
prefetchFor = _.prefetch <<< routeMeta

-- | True for routes served by the static cache/render path
-- | (`App.Main.cachedStaticPage`/`cachedInner`); false for data-backed
-- | routes (`cachedDynamicPage`/`cachedInnerDynamic`).
isStaticRoute :: Route -> Boolean
isStaticRoute = _.isStatic <<< routeMeta

-- ============================================================================
-- Parsing (derived from codec)
-- ============================================================================

-- | Parse path segments into (Lang, Route).
-- | Returns Nothing if the path doesn't match any route.
parseRoute :: Array String -> Maybe { lang :: Lang, route :: Route }
parseRoute segments =
  let
    fullPath = "/" <> joinWith "/" segments
  in
    case Map.lookup fullPath routeTable of
      Just res -> Just res
      Nothing -> do
        tag <- head segments
        lang <- parseLang tag
        case parse (routeCodec lang) fullPath of
          Right route -> Just { lang, route }
          Left _ -> Nothing

routeTable :: Map String { lang :: Lang, route :: Route }
routeTable = Map.fromFoldable
  (concatMap (\l -> map (\r -> Tuple (routeUrl l r) { lang: l, route: r }) allRoutes) allLangs)

-- ============================================================================
-- Enumerations
-- ============================================================================

-- | All routes (for sitemap generation). Static routes are enumerated here; dynamic routes like PostDetail are intentionally NOT included because they cannot be enumerated statically.
allRoutes :: Array Route
allRoutes = [ Home, About, Contact, PostList, Fixtures ]

-- | Derived from `routeMeta`, not hand-listed — see `RouteMeta` above.
staticRoutes :: Array Route
staticRoutes = filter isStaticRoute allRoutes

-- | Re-export of Data.I18n.allLangs (single source of truth).
allLangs :: Array Lang
allLangs = I18n.allLangs

-- | Page title for a route + language (for <title> tag)
routeTitle :: Lang -> Route -> String
routeTitle lang route =
  let
    d = dict lang
    siteTitle = d.common.siteTitle
  in
    case route of
      Home -> siteTitle
      About -> d.nav.about <> " | " <> siteTitle
      Contact -> d.nav.contact <> " | " <> siteTitle
      PostList -> d.nav.posts <> " | " <> siteTitle
      PostDetail _ -> d.posts.detailTitle <> " | " <> siteTitle
      Fixtures -> d.fixtures.listTitle <> " | " <> siteTitle

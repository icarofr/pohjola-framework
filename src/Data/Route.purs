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
-- |
-- | Currently zero-constructor: the whole content layer was purged for a
-- | clean-sheet rebuild (see .scratch/clean-sheet-homepage/). Every function
-- | below stays total and correct at zero routes by construction.
-- |
-- | The `routeCodec`/routing-duplex machinery described above is gone for
-- | now, not just emptied: `Routing.Duplex.Generic`'s `GRouteDuplex` class
-- | has no instance for a zero-constructor Generic rep (`NoConstructors`),
-- | so `G.sum {}` does not compile — a real library limitation, not a
-- | mistake to fix here. `routeUrl`/`parseRoute` below are total without it
-- | (Route is uninhabited, so their bodies are honestly unreachable).
-- | `routeCodec` and the codec-per-language pattern return in full the
-- | moment a real constructor exists again (ticket 02+).
module Data.Route where

import Prelude hiding ((/))

import Data.Array (concatMap, filter)
import Data.I18n (Lang, dict)
import Data.I18n as I18n
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe)
import Data.String.Common (joinWith)
import Data.Tuple (Tuple(..))

-- ============================================================================
-- Route sum type
-- ============================================================================
--
-- No `Generic` instance for now: nothing needs it while `routeCodec` (which
-- required it) is gone — see the module doc. Re-derive it alongside
-- `routeCodec` once a real constructor exists again.

data Route

derive instance eqRoute :: Eq Route
derive instance ordRoute :: Ord Route

instance showRoute :: Show Route where
  show = case _ of
    _ -> ""

-- ============================================================================
-- URL generation
-- ============================================================================

-- | Full URL path: /en/about, /fr/a-propos. Unreachable body — `Route` is
-- | currently uninhabited — kept total via the wildcard.
routeUrl :: Lang -> Route -> String
routeUrl _ = case _ of
  _ -> ""

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
  , inSitemap :: Boolean
  , prefetch :: Array Route
  }

-- | Exhaustive on Route — adding a constructor forces a caching, a sitemap,
-- | and a prefetch decision here, in one place, instead of three.
routeMeta :: Route -> RouteMeta
routeMeta = case _ of
  _ -> { isStatic: true, inSitemap: true, prefetch: [] }

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

-- | True for routes that belong in `allRoutes`/the sitemap. See `RouteMeta`
-- | for exactly what this does and doesn't guarantee.
isInSitemap :: Route -> Boolean
isInSitemap = _.inSitemap <<< routeMeta

-- ============================================================================
-- Parsing (derived from codec)
-- ============================================================================

-- | Parse path segments into (Lang, Route).
-- | Returns Nothing if the path doesn't match any route.
-- |
-- | The per-language codec fallback (for routes too dynamic to enumerate
-- | into `routeTable`, e.g. a detail page with an Int id) is gone along with
-- | `routeCodec` — see the module doc. `allRoutes` is empty, so the table
-- | lookup alone is already total and correct; the fallback returns with a
-- | dynamic route.
parseRoute :: Array String -> Maybe { lang :: Lang, route :: Route }
parseRoute segments =
  let
    fullPath = "/" <> joinWith "/" segments
  in
    Map.lookup fullPath routeTable

routeTable :: Map String { lang :: Lang, route :: Route }
routeTable = Map.fromFoldable
  (concatMap (\l -> map (\r -> Tuple (routeUrl l r) { lang: l, route: r }) allRoutes) allLangs)

-- ============================================================================
-- Enumerations
-- ============================================================================

-- | All routes (for sitemap generation). Static routes are enumerated here; dynamic routes are intentionally NOT included because they cannot be enumerated statically.
allRoutes :: Array Route
allRoutes = []

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
  in
    case route of
      _ -> d.common.siteTitle

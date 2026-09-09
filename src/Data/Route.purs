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
-- | Rebuilt from zero for the clean-sheet rebuild (see
-- | .scratch/clean-sheet-homepage/, ticket 02): `Home` is the first route
-- | back after ticket 01's purge. `routing-duplex`'s `GRouteDuplex` class has
-- | no instance for a zero-constructor Generic rep, so this file — and
-- | `App.Main`/`Data.I18n`/`App.Layout.Head`/`App.Ui.Templates.SiteShell`,
-- | which all anchor their auto-wiring regexes on an existing route entry —
-- | had to be hand-wired for `Home` specifically; `make new-feature --wire`
-- | could not bootstrap the very first route from a genuinely empty file
-- | (confirmed by running it directly, not assumed). It wires the next
-- | routes (About, Guarantees, Docs) normally, now that a real entry exists
-- | to append after — also confirmed directly, after fixing two real bugs
-- | the empty-to-one transition surfaced in scripts/auto-scaffold.js: the
-- | `data Route` regex assumed a fixed multi-line shape (purs-tidy collapses
-- | a single constructor to `data Route = Home`), and the SiteShell chrome
-- | wiring anchored on `copyright` as if it were always the last
-- | `ShellLabels` field, which it never was.
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
import Routing.Duplex (RouteDuplex', parse, prefix, print, root)
import Routing.Duplex.Generic as G
import Routing.Duplex.Generic.Syntax ((/))

-- ============================================================================
-- Route sum type
-- ============================================================================

data Route
  = Home
  | About
  | Guarantees
  | Docs

derive instance genericRoute :: Generic Route _
derive instance eqRoute :: Eq Route
derive instance ordRoute :: Ord Route

instance showRoute :: Show Route where
  show = case _ of
    Home -> "Home"

    About -> "About"

    Guarantees -> "Guarantees"

    Docs -> "Docs"

-- ============================================================================
-- Bidirectional codec — one per language
-- ============================================================================

-- | Route codec for a given language. Print and parse derive from this.
-- | Adding a route constructor but forgetting it here = compile error.
routeCodec :: Lang -> RouteDuplex' Route
routeCodec En = root $ prefix "en" $ G.sum
  { "Home": G.noArgs
  , "About": "about" / G.noArgs
  , "Guarantees": "guarantees" / G.noArgs
  , "Docs": "docs" / G.noArgs
  }
routeCodec Fr = root $ prefix "fr" $ G.sum
  { "Home": G.noArgs
  , "About": "about" / G.noArgs
  , "Guarantees": "guarantees" / G.noArgs
  , "Docs": "docs" / G.noArgs
  }
routeCodec Pt = root $ prefix "pt" $ G.sum
  { "Home": G.noArgs
  , "About": "about" / G.noArgs
  , "Guarantees": "guarantees" / G.noArgs
  , "Docs": "docs" / G.noArgs
  }

-- ============================================================================
-- URL generation (derived from codec)
-- ============================================================================

-- | Full URL path: /en/about, /fr/about (the slug is unified across
-- | languages; only the page's own copy is translated)
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
  , inSitemap :: Boolean
  , prefetch :: Array Route
  }

-- | Exhaustive on Route — adding a constructor forces a caching, a sitemap,
-- | and a prefetch decision here, in one place, instead of three.
routeMeta :: Route -> RouteMeta
routeMeta = case _ of
  Home -> { isStatic: true, inSitemap: true, prefetch: [] }
  About -> { isStatic: true, inSitemap: true, prefetch: [ Home ] }
  Guarantees -> { isStatic: true, inSitemap: true, prefetch: [ Home ] }
  Docs -> { isStatic: true, inSitemap: true, prefetch: [ Home ] }

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

-- | All routes (for sitemap generation). Static routes are enumerated here; dynamic routes are intentionally NOT included because they cannot be enumerated statically.
allRoutes :: Array Route
allRoutes = [ Home, About, Guarantees, Docs ]

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
      About -> d.nav.about <> " - " <> siteTitle
      Guarantees -> d.nav.guarantees <> " - " <> siteTitle
      Docs -> d.nav.docs <> " - " <> siteTitle

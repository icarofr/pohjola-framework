-- | Route tests — parsing, URL generation, round-trip.
-- |
-- | Trimmed for the clean-sheet rebuild (see .scratch/clean-sheet-homepage/):
-- | `Route` is temporarily zero-constructor, so the per-route `parseRoute`/
-- | `routeUrl` literal assertions are gone (nothing to name). What's generic
-- | over `allRoutes`/`allLangs` (round-trip, the `allRoutes` invariant) stays
-- | and is asserted against the current, empty enumeration.
module Test.Route.RouteSpec where

import Prelude

import Data.Array (all, filter, length)
import Data.Maybe (Maybe(..), isJust)
import Data.Route (allLangs, allRoutes, isInSitemap, parseRoute, routeUrl, staticRoutes)
import Data.String.Common (split) as S
import Data.String.Pattern (Pattern(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = do
  describe "Route" do
    describe "parseRoute" do
      it "returns Nothing for unknown route" do
        parseRoute [ "en", "unknown" ] `shouldEqual` Nothing
      it "returns Nothing for unknown lang" do
        parseRoute [ "de" ] `shouldEqual` Nothing
      it "returns Nothing for empty path" do
        parseRoute [] `shouldEqual` Nothing

    describe "round-trip" do
      it "parseRoute (splitPath (routeUrl lang route)) = Just for all lang × route" do
        let
          allPairs = do
            lang <- allLangs
            route <- allRoutes
            pure { lang, route }
          results = map (\p -> parseRoute (splitPath (routeUrl p.lang p.route))) allPairs
        all isJust results `shouldEqual` true

      it "covers all lang × route combinations" do
        let total = length allLangs * length allRoutes
        total `shouldEqual` 0 -- 3 langs * 0 routes — zero-constructor Route, clean-sheet rebuild

    describe "allRoutes" do
      -- allRoutes is necessarily a hand-written literal (Route isn't
      -- Bounded/Enum, and a dynamic route's Int arg can't be enumerated
      -- regardless — see the comment on RouteMeta in Data.Route). `all
      -- isInSitemap allRoutes` is the mechanically-checkable half of that:
      -- isInSitemap comes from routeMeta, an exhaustive case with no wildcard
      -- arm, so every Route constructor is forced to carry an explicit
      -- inSitemap decision — this test catches that literal disagreeing with
      -- it. It cannot catch a constructor whose routeMeta entry was written
      -- correctly but never added to the allRoutes literal at all.
      it "enumerates sitemap routes" do
        allRoutes `shouldEqual` []
        staticRoutes `shouldEqual` []
        all isInSitemap allRoutes `shouldEqual` true

splitPath :: String -> Array String
splitPath p = filter (_ /= "") (S.split (Pattern "/") p)

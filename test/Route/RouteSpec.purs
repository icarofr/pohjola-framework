-- | Route tests — parsing, URL generation, round-trip.
module Test.Route.RouteSpec where

import Prelude

import Data.Array (all, filter, length)
import Data.I18n (Lang(..))
import Data.Maybe (Maybe(..), isJust)
import Data.Route (Route(..), allLangs, allRoutes, isInSitemap, parseRoute, routeUrl, staticRoutes)
import Data.String.Common (split) as S
import Data.String.Pattern (Pattern(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = do
  describe "Route" do
    describe "parseRoute" do
      it "parses /en as Home" do
        parseRoute [ "en" ] `shouldEqual` Just { lang: En, route: Home }
      it "parses /fr as Home" do
        parseRoute [ "fr" ] `shouldEqual` Just { lang: Fr, route: Home }
      it "parses /pt as Home" do
        parseRoute [ "pt" ] `shouldEqual` Just { lang: Pt, route: Home }
      it "returns Nothing for unknown route" do
        parseRoute [ "en", "unknown" ] `shouldEqual` Nothing
      it "returns Nothing for unknown lang" do
        parseRoute [ "de" ] `shouldEqual` Nothing
      it "returns Nothing for empty path" do
        parseRoute [] `shouldEqual` Nothing

    describe "routeUrl" do
      it "generates /en for Home" do
        routeUrl En Home `shouldEqual` "/en"
      it "generates /fr for Home" do
        routeUrl Fr Home `shouldEqual` "/fr"
      it "generates /pt for Home" do
        routeUrl Pt Home `shouldEqual` "/pt"

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
        total `shouldEqual` 3 -- 3 langs * 1 route (Home)

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
        allRoutes `shouldEqual` [ Home ]
        staticRoutes `shouldEqual` [ Home ]
        all isInSitemap allRoutes `shouldEqual` true

splitPath :: String -> Array String
splitPath p = filter (_ /= "") (S.split (Pattern "/") p)

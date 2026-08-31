-- | Route tests — parsing, URL generation, round-trip
module Test.Route.RouteSpec where

import Prelude

import Data.Array (all, filter, length)
import Data.I18n (Lang(..))
import Data.Maybe (Maybe(..), isJust)
import Data.Route (Route(..), allLangs, allRoutes, parseRoute, routeUrl)
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
      it "parses /en/about" do
        parseRoute [ "en", "about" ] `shouldEqual` Just { lang: En, route: About }
      it "parses /fr/a-propos" do
        parseRoute [ "fr", "a-propos" ] `shouldEqual` Just { lang: Fr, route: About }
      it "parses /en/contact" do
        parseRoute [ "en", "contact" ] `shouldEqual` Just { lang: En, route: Contact }
      it "parses /fr/contact" do
        parseRoute [ "fr", "contact" ] `shouldEqual` Just { lang: Fr, route: Contact }
      it "parses /en/posts as PostList" do
        parseRoute [ "en", "posts" ] `shouldEqual` Just { lang: En, route: PostList }
      it "parses /fr/articles as PostList" do
        parseRoute [ "fr", "articles" ] `shouldEqual` Just { lang: Fr, route: PostList }
      it "parses /en/posts/42 as PostDetail 42" do
        parseRoute [ "en", "posts", "42" ] `shouldEqual` Just { lang: En, route: PostDetail 42 }
      it "parses /fr/articles/7 as PostDetail 7" do
        parseRoute [ "fr", "articles", "7" ] `shouldEqual` Just { lang: Fr, route: PostDetail 7 }
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
      it "generates /en/about" do
        routeUrl En About `shouldEqual` "/en/about"
      it "generates /fr/a-propos" do
        routeUrl Fr About `shouldEqual` "/fr/a-propos"
      it "generates /en/contact" do
        routeUrl En Contact `shouldEqual` "/en/contact"
      it "generates /fr/contact" do
        routeUrl Fr Contact `shouldEqual` "/fr/contact"
      it "generates /en/posts for PostList" do
        routeUrl En PostList `shouldEqual` "/en/posts"
      it "generates /fr/articles for PostList" do
        routeUrl Fr PostList `shouldEqual` "/fr/articles"
      it "generates /en/posts/42 for PostDetail 42" do
        routeUrl En (PostDetail 42) `shouldEqual` "/en/posts/42"
      it "generates /fr/articles/7 for PostDetail 7" do
        routeUrl Fr (PostDetail 7) `shouldEqual` "/fr/articles/7"

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
        total `shouldEqual` 12 -- 3 langs * 4 routes

splitPath :: String -> Array String
splitPath p = filter (_ /= "") (S.split (Pattern "/") p)

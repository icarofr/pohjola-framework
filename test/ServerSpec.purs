module Test.ServerSpec where

import Prelude

import App.Bun (wyhash)
import App.Server (ResponseBody(..), isUnsafePath, notModified, sseEventResponse, sseEventResponseMatching, sseNoStoreEventResponse)
import Data.Array (find, mapMaybe, last)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..), snd)
import Effect.Class (liftEffect)
import Test.Spec (describe, it, Spec)
import Test.Spec.Assertions (shouldEqual, shouldNotEqual)

lastHeaderValue :: String -> Array (Tuple String String) -> Maybe String
lastHeaderValue key headers =
  last (mapMaybe (\(Tuple k v) -> if k == key then Just v else Nothing) headers)

headerValue :: String -> Array (Tuple String String) -> Maybe String
headerValue key headers = snd <$> find (\(Tuple k _) -> k == key) headers

spec :: Spec Unit
spec = do
  describe "Server utilities" do
    it "rejects unsafe paths" do
      isUnsafePath [ "..", "etc" ] `shouldEqual` true
      isUnsafePath [ "a", "b" ] `shouldEqual` false
      isUnsafePath [ "css", "styles.css" ] `shouldEqual` false

    describe "Bun.hash.wyhash" do
      it "hashes strings deterministically and uniquely" do
        let h1 = wyhash "hello world"
        let h2 = wyhash "hello world"
        let h3 = wyhash "hello world!"
        h1 `shouldEqual` h2
        h1 `shouldNotEqual` h3
        h1 `shouldNotEqual` ""

    describe "notModified response" do
      it "constructs 304 response with security headers and empty body" do
        let resp = notModified [ Tuple "ETag" "W/\"12345\"" ]
        resp.status `shouldEqual` 304
        case resp.body of
          StringBody body -> body `shouldEqual` ""
          _ -> shouldEqual true false

    describe "sseEventResponse cache policy" do
      -- `private` is the sharing rule (no CDN). `max-age=180` is a separate
      -- product choice: long enough for hover → click inside a short session,
      -- short enough that a deploy's stale copy dies in minutes. The ETag is
      -- a strong validator (RFC 9110: byte-identity, not W/) of the SSE
      -- bytes via wyhash.
      let event = "event: datastar-patch-elements\ndata: elements <div id=\"content\"></div>\n\n"
      it "successful patches are private, max-age=180, and carry a strong ETag of the event bytes" do
        resp <- liftEffect $ sseEventResponse event
        resp.status `shouldEqual` 200
        headerValue "Cache-Control" resp.headers `shouldEqual` Just "private, max-age=180"
        lastHeaderValue "ETag" resp.headers `shouldEqual` Just ("\"" <> wyhash event <> "\"")
      it "the same body produces the same ETag" do
        a <- liftEffect $ sseEventResponse event
        b <- liftEffect $ sseEventResponse event
        lastHeaderValue "ETag" a.headers `shouldEqual` lastHeaderValue "ETag" b.headers
      it "If-None-Match matching the ETag is 304 with empty body" do
        ok <- liftEffect $ sseEventResponse event
        case lastHeaderValue "ETag" ok.headers of
          Nothing -> shouldEqual true false
          Just tag -> do
            cached <- liftEffect $ sseEventResponseMatching (Just tag) event
            cached.status `shouldEqual` 304
            lastHeaderValue "ETag" cached.headers `shouldEqual` Just tag
            headerValue "Cache-Control" cached.headers `shouldEqual` Just "private, max-age=180"
            case cached.body of
              StringBody body -> body `shouldEqual` ""
              _ -> shouldEqual true false
      it "If-None-Match that does not match still returns 200" do
        resp <- liftEffect $ sseEventResponseMatching (Just "\"deadbeef\"") event
        resp.status `shouldEqual` 200
      it "no-store patches (errors, statusful banners) carry no ETag" do
        resp <- liftEffect $ sseNoStoreEventResponse event
        resp.status `shouldEqual` 200
        headerValue "Cache-Control" resp.headers `shouldEqual` Just "no-store"
        lastHeaderValue "ETag" resp.headers `shouldEqual` Nothing
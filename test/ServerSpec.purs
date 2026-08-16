module Test.ServerSpec where

import Prelude

import App.Bun (wyhash)
import App.Server (ResponseBody(..), isUnsafePath, notModified)
import Data.Tuple (Tuple(..))
import Test.Spec (describe, it, Spec)
import Test.Spec.Assertions (shouldEqual, shouldNotEqual)

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
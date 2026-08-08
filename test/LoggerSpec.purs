-- | Logger tests — the pure renderLogLine seam, no I/O.
module Test.LoggerSpec where

import Prelude

import App.Logger (Level(..), levelString, renderLogLine)
import Data.Tuple (Tuple(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Assertions.String (shouldContain)

spec :: Spec Unit
spec = do
  describe "App.Logger" do
    it "levelString maps each level" do
      levelString Info `shouldEqual` "info"
      levelString Warn `shouldEqual` "warn"
      levelString Err `shouldEqual` "error"

    it "renders ts/level/msg in fixed key order" do
      renderLogLine Info "hello" [] "2026-01-01T00:00:00.000Z"
        `shouldEqual` "{\"ts\":\"2026-01-01T00:00:00.000Z\",\"level\":\"info\",\"msg\":\"hello\"}"

    it "appends fields after the fixed keys" do
      renderLogLine Err "request failed" [ Tuple "rid" "req-1", Tuple "status" "500" ] "t0"
        `shouldEqual` "{\"ts\":\"t0\",\"level\":\"error\",\"msg\":\"request failed\",\"rid\":\"req-1\",\"status\":\"500\"}"

    it "escapes quotes and backslashes in msg and fields" do
      renderLogLine Info "a\"b\\c" [] "t0"
        `shouldEqual` "{\"ts\":\"t0\",\"level\":\"info\",\"msg\":\"a\\\"b\\\\c\"}"

    it "escapes newlines inside fields" do
      renderLogLine Warn "m" [ Tuple "stack" "l1\nl2" ] "t0" `shouldContain` "\\n"

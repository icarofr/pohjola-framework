-- | Server utility tests
module Test.ServerSpec where

import Prelude

import App.Server (isUnsafePath)
import Test.Spec (describe, it, Spec)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = do
  describe "Server utilities" do
    it "rejects unsafe paths" do
      isUnsafePath [ "..", "etc" ] `shouldEqual` true
      isUnsafePath [ "a", "b" ] `shouldEqual` false
      isUnsafePath [ "css", "styles.css" ] `shouldEqual` false
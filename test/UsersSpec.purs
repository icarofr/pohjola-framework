-- | User account tests (ADR-002, App.Users). Tests the one pure,
-- | directly-testable piece: decodeLoginCandidate. createUser/
-- | findUserByEmail/verifyUserPassword/linkOAuthAccount/
-- | findUserByOAuthAccount all require a live Postgres connection and
-- | are not unit-tested here — same honest limitation already
-- | documented for App.Auth's SQL-backed functions and
-- | App.Features.Posts.Service's SQL-configured branch.
module Test.UsersSpec (spec) where

import Prelude

import App.Auth (UserId(..))
import App.Users (decodeLoginCandidate)
import Data.Maybe (Maybe(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = do
  describe "App.Users" do
    describe "decodeLoginCandidate" do
      it "decodes a row with both id and password_hash present" do
        decodeLoginCandidate (Just "user-42") (Just "argon2id-hash")
          `shouldEqual` Just { userId: UserId "user-42", passwordHash: "argon2id-hash" }

      it "reports Nothing for an OAuth-only account (no password set)" do
        decodeLoginCandidate (Just "user-42") Nothing `shouldEqual` Nothing

      it "reports Nothing when id is missing (defensive — shouldn't happen for a real row)" do
        decodeLoginCandidate Nothing (Just "argon2id-hash") `shouldEqual` Nothing

      it "reports Nothing when both fields are missing" do
        decodeLoginCandidate Nothing Nothing `shouldEqual` Nothing

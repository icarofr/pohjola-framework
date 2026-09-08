-- | Auth and session lifecycle contract tests (ADR-002, amended: Lucia's
-- | session pattern). Tests the pure, directly-testable surface: cookie
-- | name/parse/format, token splitting, and the session-validity decision
-- | (`checkSession`). `createSession`/`requireAuth`/`destroySession`
-- | themselves require a live Postgres connection (App.Data.SQL.connect)
-- | and are not unit-tested here — same honest limitation already
-- | documented for App.Features.Posts.Service's SQL-configured branch.
module Test.AuthSpec (spec) where

import Prelude

import App.Auth
  ( SessionCheck(..)
  , UserId(..)
  , checkSession
  , formatClearSessionCookie
  , formatSessionCookie
  , parseSessionCookie
  , sessionCookieName
  , splitToken
  )
import App.Bun (hashPassword, verifyPassword)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual, shouldNotEqual, shouldSatisfy)
import Test.Spec.Assertions.String (shouldContain)

spec :: Spec Unit
spec = do
  describe "App.Auth" do
    describe "Cookie naming" do
      it "uses __Host- prefix only when secure" do
        sessionCookieName true `shouldEqual` "__Host-ps_session"
        sessionCookieName false `shouldEqual` "ps_session"

    describe "Cookie parsing" do
      it "extracts the session token from a secure cookie header" do
        (parseSessionCookie true "__Host-ps_session=abc.def" >>= splitToken)
          `shouldEqual` Just { id: "abc", secret: "def" }

      it "extracts the session token from an insecure-dev cookie header, ignoring unrelated cookies" do
        (parseSessionCookie false "theme=dark; ps_session=xyz.token; lang=en" >>= splitToken)
          `shouldEqual` Just { id: "xyz", secret: "token" }

      it "does not match a secure cookie name against an insecure header, or vice versa" do
        (parseSessionCookie true "ps_session=abc.def" >>= splitToken) `shouldEqual` Nothing
        (parseSessionCookie false "__Host-ps_session=abc.def" >>= splitToken) `shouldEqual` Nothing

      it "returns Nothing when the cookie is absent" do
        (parseSessionCookie true "theme=dark; lang=en" >>= splitToken) `shouldEqual` Nothing
        (parseSessionCookie true "" >>= splitToken) `shouldEqual` Nothing

    describe "Token splitting" do
      it "splits a well-formed id.secret token" do
        (parseSessionCookie false "ps_session=sessionid.sessionsecret" >>= splitToken)
          `shouldEqual` Just { id: "sessionid", secret: "sessionsecret" }

      it "rejects a token with no separator or more than one" do
        (parseSessionCookie false "ps_session=noseparator" >>= splitToken) `shouldEqual` Nothing
        (parseSessionCookie false "ps_session=too.many.dots" >>= splitToken) `shouldEqual` Nothing

    describe "Cookie formatting" do
      it "formats a secure cookie with __Host- prefix, Secure, HttpOnly, SameSite=Lax" do
        case parseSessionCookie true "__Host-ps_session=abc.def" of
          Nothing -> fail "expected a parsed token"
          Just tok -> do
            let cookie = formatSessionCookie true tok
            cookie `shouldContain` "__Host-ps_session=abc.def"
            cookie `shouldContain` "Secure"
            cookie `shouldContain` "HttpOnly"
            cookie `shouldContain` "SameSite=Lax"
            cookie `shouldContain` "Max-Age=864000"

      it "formats an insecure-dev cookie without Secure or the __Host- prefix" do
        case parseSessionCookie false "ps_session=abc.def" of
          Nothing -> fail "expected a parsed token"
          Just tok -> do
            let cookie = formatSessionCookie false tok
            cookie `shouldContain` "ps_session=abc.def"
            cookie `shouldSatisfy` (\c -> not (String.contains (Pattern "Secure") c))
            cookie `shouldSatisfy` (\c -> not (String.contains (Pattern "__Host-") c))

    describe "Clear-cookie formatting" do
      it "formats a secure clear-cookie with Max-Age=0" do
        let cleared = formatClearSessionCookie true
        cleared `shouldContain` "__Host-ps_session="
        cleared `shouldContain` "Max-Age=0"
        cleared `shouldContain` "Secure"

      it "formats an insecure-dev clear-cookie without Secure" do
        let cleared = formatClearSessionCookie false
        cleared `shouldContain` "ps_session="
        cleared `shouldContain` "Max-Age=0"

    describe "checkSession — the pure session-validity decision" do
      it "reports expiry regardless of hash/user_id state" do
        checkSession { expired: true, storedHash: Just "hash", userId: Just "user-1" } "hash"
          `shouldEqual` SessionExpired
        checkSession { expired: true, storedHash: Nothing, userId: Nothing } "hash"
          `shouldEqual` SessionExpired

      it "reports a valid session when not expired and the hash matches" do
        checkSession { expired: false, storedHash: Just "correct-hash", userId: Just "user-42" } "correct-hash"
          `shouldEqual` SessionValid (UserId "user-42")

      it "reports a mismatch when the computed hash disagrees with the stored one" do
        checkSession { expired: false, storedHash: Just "stored-hash", userId: Just "user-42" } "wrong-hash"
          `shouldEqual` SessionSecretMismatch

      it "reports a mismatch when the row is missing expected fields" do
        checkSession { expired: false, storedHash: Nothing, userId: Just "user-42" } "any-hash"
          `shouldEqual` SessionSecretMismatch
        checkSession { expired: false, storedHash: Just "hash", userId: Nothing } "hash"
          `shouldEqual` SessionSecretMismatch

    describe "Native Argon2id Password Hashing (Bun.password)" do
      it "hashes password and verifies match correctly" do
        let plain = "super-secret-password-123"
        eHash <- hashPassword plain
        case eHash of
          Left err -> fail ("hashPassword failed: " <> err)
          Right hash -> do
            hash `shouldNotEqual` plain
            hash `shouldContain` "argon2"

            -- Matching password verifies True
            valid <- verifyPassword plain hash
            valid `shouldEqual` Right true

            -- Wrong password verifies False
            invalid <- verifyPassword "wrong-password" hash
            invalid `shouldEqual` Right false

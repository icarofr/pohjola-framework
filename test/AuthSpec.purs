-- | Auth and session lifecycle contract tests (ADR-002, ADR-004, ADR-005)
module Test.AuthSpec (spec) where

import Prelude

import App.Auth (Session(..), SessionId(..), UserId(..), createSession, destroySession, formatClearSessionCookie, formatSessionCookie, mkSessionStore, parseSessionCookie, requireAuth)
import App.Error (AppError(..))
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect.Class (liftEffect)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Assertions.String (shouldContain)

spec :: Spec Unit
spec = do
  describe "App.Auth" do
    describe "Cookie parsing and formatting" do
      it "extracts session_id from cookie header" do
        parseSessionCookie "session_id=abc123token" `shouldEqual` Just (SessionId "abc123token")
        parseSessionCookie "theme=dark; session_id=xyz789; lang=en" `shouldEqual` Just (SessionId "xyz789")
        parseSessionCookie "theme=dark; lang=en" `shouldEqual` Nothing
        parseSessionCookie "" `shouldEqual` Nothing

      it "formats secure HttpOnly SameSite cookie" do
        let cookie = formatSessionCookie (SessionId "token999") 86400
        cookie `shouldContain` "session_id=token999"
        cookie `shouldContain` "HttpOnly"
        cookie `shouldContain` "SameSite=Lax"
        cookie `shouldContain` "Max-Age=86400"

      it "formats clear cookie with Max-Age=0" do
        let clear = formatClearSessionCookie
        clear `shouldContain` "session_id="
        clear `shouldContain` "Max-Age=0"

    describe "Session store lifecycle" do
      it "creates, resolves and destroys sessions" do
        store <- liftEffect mkSessionStore
        let uid = UserId "user-42"
        let token = "secret-token-xyz"

        -- Initially not authenticated
        initial <- requireAuth store (Just "session_id=secret-token-xyz")
        initial `shouldEqual` Left NotFound

        -- Create session
        created <- createSession store uid token
        created `shouldEqual` Right (SessionId token)

        -- Resolve session
        authed <- requireAuth store (Just "session_id=secret-token-xyz")
        authed `shouldEqual` Right (Session { userId: uid, sessionId: SessionId token })

        -- Destroy session
        destroyed <- destroySession store (SessionId token)
        destroyed `shouldEqual` Right unit

        -- After logout, session is not found
        afterLogout <- requireAuth store (Just "session_id=secret-token-xyz")
        afterLogout `shouldEqual` Left NotFound

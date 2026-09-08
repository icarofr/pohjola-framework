-- | Posts decoding tests — exercises the DecodeJson instance without network
module Test.PostsSpec where

import Prelude

import App.Data.Fetch (statusToAppError)
import App.Data.SQL (SQLError(..))
import App.Data.SQL as SQL
import App.Error (AppError(..))
import App.Features.Posts.Service (postFromRows, postsFromRows)
import App.Features.Posts.Types (Post(..), postExcerpt)
import Data.Argonaut.Decode.Error (JsonDecodeError(..))
import Data.Array as Array
import Data.Argonaut.Core (Json, fromObject, fromNumber, fromString)
import Data.Argonaut.Decode (decodeJson)
import Data.Either (Either(..))
import Data.Int (toNumber)
import Data.String as String
import Data.Tuple (Tuple(..))
import Foreign (unsafeToForeign)
import Foreign.Object as Object
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual, shouldSatisfy)

-- | A DbRow is Foreign, and readStringField/readIntField do plain `row[field]`
-- | property access (App.Data.SQL.js) -- so a compiled PS record literal is a
-- | valid DbRow fixture with zero DB involved.
validRow :: SQL.DbRow
validRow = unsafeToForeign { id: 1, user_id: 1, title: "Hello World", body: "Body text." }

-- | Missing "title" -- decodePostRow's Maybe chain fails on this field.
malformedRow :: SQL.DbRow
malformedRow = unsafeToForeign { id: 1, user_id: 1 }

-- | Sample JSON matching JSONPlaceholder's post shape.
-- | Lives in the test (not Types.purs) — test data doesn't belong in
-- | production modules.
samplePostJson :: Json
samplePostJson = fromObject $ Object.fromFoldable
  [ Tuple "id" (fromNumber (toNumber 1))
  , Tuple "userId" (fromNumber (toNumber 1))
  , Tuple "title" (fromString "Hello World")
  , Tuple "body" (fromString "This is a test post.")
  ]

spec :: Spec Unit
spec = do
  describe "Post decoding" do
    it "decodes a valid JSON object" do
      case decodeJson samplePostJson of
        Right (Post p) -> do
          p.id `shouldEqual` 1
          p.userId `shouldEqual` 1
          p.title `shouldEqual` "Hello World"
          p.body `shouldEqual` "This is a test post."
        Left err -> fail ("Expected Right, got Left: " <> show err)

    it "fails to decode JSON missing required fields" do
      let
        badJson = fromObject $ Object.fromFoldable
          [ Tuple "id" (fromNumber (toNumber 1))
          , Tuple "userId" (fromNumber (toNumber 1))
          ]
      case decodeJson badJson :: Either _ Post of
        Left _ -> pure unit
        Right _ -> fail "Expected decode failure for missing fields"

  describe "postExcerpt" do
    it "flattens newlines and keeps short bodies intact" do
      let post = Post { id: 1, userId: 1, title: "T", body: "Line one.\n\nLine two." }
      postExcerpt post `shouldEqual` "Line one. Line two."

    it "truncates long bodies with an ellipsis" do
      let
        longBody = String.joinWith " " (Array.replicate 40 "word")
        post = Post { id: 1, userId: 1, title: "T", body: longBody }
      String.length (postExcerpt post) `shouldSatisfy` (_ <= 165)

  describe "postFromRows (fetchPost's SQL-branch decision, no DB required)" do
    it "surfaces a real SQL error as DecodeError, not NotFound" do
      postFromRows (Left (QueryError "connection reset"))
        `shouldEqual` Left (DecodeError (TypeMismatch "QueryError: connection reset"))

    it "reports zero rows as NotFound" do
      postFromRows (Right []) `shouldEqual` Left NotFound

    it "decodes a single valid row" do
      postFromRows (Right [ validRow ])
        `shouldEqual` Right (Post { id: 1, userId: 1, title: "Hello World", body: "Body text." })

    it "reports a malformed row as DecodeError, not NotFound (the post exists, it's malformed)" do
      postFromRows (Right [ malformedRow ])
        `shouldEqual` Left (DecodeError (TypeMismatch "post: row failed to decode"))

  describe "postsFromRows (fetchPosts' SQL-branch decision, no DB required)" do
    it "surfaces a real SQL error as DecodeError" do
      postsFromRows (Left (QueryError "connection reset"))
        `shouldEqual` Left (DecodeError (TypeMismatch "QueryError: connection reset"))

    it "reports an empty table as Right [] -- a valid production state, not demo mode" do
      postsFromRows (Right []) `shouldEqual` Right []

    it "decodes rows that are all valid" do
      postsFromRows (Right [ validRow ])
        `shouldEqual` Right [ Post { id: 1, userId: 1, title: "Hello World", body: "Body text." } ]

    it "reports all-rows-failed-to-decode as DecodeError, not an empty demo fallback" do
      postsFromRows (Right [ malformedRow ])
        `shouldEqual` Left (DecodeError (TypeMismatch "posts: all rows failed to decode"))

  describe "fetchJson status mapping" do
    it "maps 200 to Right" do
      case statusToAppError 200 of
        Right _ -> pure unit
        Left err -> fail ("Expected Right, got Left: " <> show err)

    it "maps 404 to NotFound" do
      case statusToAppError 404 of
        Left NotFound -> pure unit
        _ -> fail "Expected NotFound Left"

    it "maps other status codes to HttpStatusError" do
      case statusToAppError 500 of
        Left (HttpStatusError 500) -> pure unit
        _ -> fail "Expected HttpStatusError 500"

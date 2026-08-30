-- | Posts decoding tests — exercises the DecodeJson instance without network
module Test.PostsSpec where

import Prelude

import App.Data.Fetch (statusToAppError)
import App.Error (AppError(..))
import App.Features.Posts.Types (Post(..), postExcerpt)
import Data.Array as Array
import Data.Argonaut.Core (Json, fromObject, fromNumber, fromString)
import Data.Argonaut.Decode (decodeJson)
import Data.Either (Either(..))
import Data.Int (toNumber)
import Data.String as String
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual, shouldSatisfy)

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

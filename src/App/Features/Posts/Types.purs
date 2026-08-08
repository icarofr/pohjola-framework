-- | Post domain type + JSON decoding.
-- |
-- | Demonstrates the data layer pattern: newtype wrappers, Argonaut DecodeJson,
-- | field decoding via the `.:` operator. This is the template an agent copies
-- | to build a CMS-backed feature (Directus, Contentful, custom API).
module App.Features.Posts.Types where

import Prelude

import Data.Argonaut.Decode (class DecodeJson, decodeJson, (.:))
import Data.Argonaut.Decode.Error (JsonDecodeError(..))
import Data.Argonaut.Parser (jsonParser)
import Data.Either (Either(..))
import Data.Newtype (class Newtype)
import App.Error (AppError(..))

-- | A blog post / article fetched from an external API (JSONPlaceholder).
-- | In a real app this would be your CMS record.
newtype Post = Post
  { id :: Int
  , userId :: Int
  , title :: String
  , body :: String
  }

derive instance newtypePost :: Newtype Post _
derive newtype instance showPost :: Show Post
derive newtype instance eqPost :: Eq Post

-- | DecodeJson is the contract: the compiler verifies field names match.
-- | JSONPlaceholder returns { id, userId, title, body } — already snake_case,
-- | so no transform needed. For camelCase domain fields from snake_case JSON,
-- | see docs/examples/Snake.purs.
instance decodeJsonPost :: DecodeJson Post where
  decodeJson json = do
    obj <- decodeJson json
    id <- obj .: "id"
    userId <- obj .: "userId"
    title <- obj .: "title"
    body <- obj .: "body"
    pure $ Post { id, userId, title, body }

-- | Shared decoder for an array of posts.
decodePosts :: String -> Either AppError (Array Post)
decodePosts body = case jsonParser body of
  Left _ -> Left (DecodeError (TypeMismatch "Failed to parse posts JSON"))
  Right json -> case decodeJson json of
    Left _ -> Left (DecodeError (TypeMismatch "Failed to parse posts JSON"))
    Right posts -> Right posts

-- | Accessors
postId :: Post -> Int
postId (Post p) = p.id

postTitle :: Post -> String
postTitle (Post p) = p.title

postBody :: Post -> String
postBody (Post p) = p.body

postUserId :: Post -> Int
postUserId (Post p) = p.userId

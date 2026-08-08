-- | Data service — fetches posts from an external API via Bun native fetch.
-- |
-- | This is the data layer pattern: boundary functions return
-- | `Aff (Either AppError a)`. Callers pattern-match exhaustively.
-- | Errors are values (AppError), not exceptions.
-- |
-- | In a real app, swap JSONPlaceholder for your CMS (Directus, Contentful).
-- | The pattern stays the same: Bun native fetch via App.FetchBun → Argonaut decode → Either.
module App.Features.Posts.Service where

import Prelude
import App.Config (Config)
import App.Data.Fetch (fetchJson)
import App.Error (AppError)
import App.Features.Posts.Types (Post)
import Data.Either (Either)
import Effect.Aff (Aff)

-- | Fetch all posts from the API.
fetchPosts :: Config -> Aff (Either AppError (Array Post))
fetchPosts cfg =
  fetchJson (cfg.postsApiBase <> "/posts")

-- | Fetch a single post by ID.
fetchPost :: Config -> Int -> Aff (Either AppError Post)
fetchPost cfg id =
  fetchJson (cfg.postsApiBase <> "/posts/" <> show id)

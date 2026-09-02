-- | Posts page — entry point with async data fetching.
-- |
-- | This is the key difference from static pages: the render function is
-- | `Aff (Either AppError Html)`, not pure `Html`. The router awaits the
-- | result and handles errors (404, 500) with rendered error pages.
-- |
-- | Pattern for any data-backed page:
-- |   1. Fetch data via a Service module (returns `Aff (Either AppError a)`)
-- |   2. Pattern-match: Right data → render view, Left err → render error
-- |   3. The router maps AppError to HTTP status codes
module App.Features.Posts.Page (renderList, renderDetail) where

import Prelude

import App.Config (Config)
import App.Error (AppError)
import App.Features.Posts.Service (fetchPost, fetchPosts)
import App.Features.Posts.View (renderPostDetail, renderPostList, renderPostsError)
import App.Form (FormStatus)
import App.Html (Html)
import Data.Either (Either(..))
import Data.I18n (Lang)
import Data.Maybe (Maybe)
import Effect.Aff (Aff)

-- | Post list page — fetches all posts, renders list or feature-specific error.
-- | A fetch failure returns `Right (renderPostsError ...)` (a 200 with an
-- | error message in-page), not `Left err` (which would render a generic 500).
-- | This is the right call for a list page: the user sees a retryable error
-- | in context, not a blank 500. For detail pages, NotFound maps to a 404.
renderList :: Config -> Lang -> Maybe FormStatus -> Aff (Either AppError Html)
renderList cfg lang status = do
  result <- fetchPosts cfg
  pure case result of
    Right posts -> Right (renderPostList lang status posts)
    Left _ -> Right (renderPostsError lang status)

-- | Post detail page — fetches a single post by ID.
-- | NotFound propagates as Left so the router renders the branded 404 page
-- | (status 404, bilingual copy) instead of a soft-404 at status 200.
renderDetail :: Config -> Lang -> Int -> Maybe FormStatus -> Aff (Either AppError Html)
renderDetail cfg lang id status = do
  result <- fetchPost cfg id
  pure case result of
    Right post -> Right (renderPostDetail lang status post)
    Left err -> Left err

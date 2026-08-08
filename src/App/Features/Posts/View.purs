-- | Posts view — list and detail rendering
module App.Features.Posts.View where

import Prelude

import App.Alpine (spaLink, xAutofocus)
import App.Features.Posts.Types (Post, postId, postTitle, postBody, postUserId)
import App.Html (Html, attr, class_, el, text)
import Data.Array (take)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

-- | Post list page — shows up to 10 posts with links to detail pages.
-- | Data is fetched in the Page module (Aff), passed in as a pure argument.
renderPostList :: Lang -> Array Post -> Html
renderPostList lang posts =
  let
    d = (dict lang).posts
  in
    el "div" [ class_ "mx-auto max-w-3xl px-4 py-16 sm:px-6 lg:px-8" ]
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text d.listTitle ]
      , el "div" [ class_ "mt-8 space-y-6" ]
          [ foldMap (renderPostCard lang) (take 10 posts) ]
      ]

-- | Individual post card in the list — links to PostDetail via spaLink.
renderPostCard :: Lang -> Post -> Html
renderPostCard lang post =
  let
    d = (dict lang).posts
  in
    el "article" [ class_ "rounded-lg border border-slate-200 dark:border-slate-800 p-6 hover:border-blue-300 dark:hover:border-blue-700 transition-colors" ]
      [ el "h2" [ class_ "text-xl font-semibold text-slate-900 dark:text-white" ]
          [ spaLink lang (PostDetail (postId post))
              [ class_ "hover:text-blue-600 dark:hover:text-blue-400 transition-colors" ]
              [ text (postTitle post) ]
          ]
      , el "p" [ class_ "mt-2 text-sm text-slate-600 dark:text-slate-400 line-clamp-2" ]
          [ text (postBody post) ]
      , el "p" [ class_ "mt-3 text-xs text-slate-400" ]
          [ text (d.byAuthor <> " " <> d.unknownAuthor <> " " <> show (postUserId post)) ]
      ]

-- | Post detail page — shows a single post with a back link.
renderPostDetail :: Lang -> Post -> Html
renderPostDetail lang post =
  let
    d = (dict lang).posts
  in
    el "div" [ class_ "mx-auto max-w-3xl px-4 py-16 sm:px-6 lg:px-8" ]
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text (postTitle post) ]
      , el "p" [ class_ "mt-2 text-sm text-slate-400" ]
          [ text (d.byAuthor <> " " <> d.unknownAuthor <> " " <> show (postUserId post)) ]
      , el "div" [ class_ "mt-8 prose prose-slate dark:prose-invert max-w-none" ]
          [ el "p" [ class_ "text-slate-600 dark:text-slate-300 leading-7 whitespace-pre-line" ]
              [ text (postBody post) ]
          ]
      , el "div" [ class_ "mt-8" ]
          [ spaLink lang PostList
              [ class_ "text-sm font-medium text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 transition-colors" ]
              [ text d.backToList ]
          ]
      ]

-- | Error state — shown when the API fetch fails.
renderPostsError :: Lang -> Html
renderPostsError lang =
  let
    d = (dict lang).posts
  in
    el "div" [ class_ "mx-auto max-w-3xl px-4 py-16 sm:px-6 lg:px-8" ]
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text d.listTitle ]
      , el "p" [ class_ "mt-4 text-lg text-red-600 dark:text-red-400" ]
          [ text d.loadingError ]
      ]


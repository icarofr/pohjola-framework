-- | Post card — presentational component for a single post in a list.
module App.Features.Posts.Components.PostCard where

import Prelude

import App.Alpine (spaLink)
import App.Features.Posts.Types (Post, postId, postTitle, postBody, postUserId)
import App.Html (Html, class_, el, text)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

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

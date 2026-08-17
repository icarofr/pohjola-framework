-- | Posts view — list and detail rendering using pure DaisyUI components
module App.Features.Posts.View where

import Prelude

import App.Alpine (spaLink)
import App.Features.Posts.Components.PostCard (renderPostCard)
import App.Features.Posts.Types (Post, postBody, postId, postTitle)
import App.Html (Html, attr, class_, el, text)
import App.Ui as Ui
import App.Ui.Container (container)
import Data.Array (take)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))

-- | Post list page — shows up to 9 posts in an aligned 3-column grid.
renderPostList :: Lang -> Array Post -> Html
renderPostList lang posts =
  let
    d = (dict lang).posts
    navDict = (dict lang).nav
  in
    Ui.pageLayout
      { header:
          Ui.pageHeader
            { category: Just navDict.posts
            , title: d.listTitle
            , subtitle: Nothing
            }
      , content:
          Ui.grid3 (map (renderPostCard lang) (take 9 posts))
      }

-- | Post detail page — shows a single post with a back link and rich layout.
renderPostDetail :: Lang -> Post -> Html
renderPostDetail lang post =
  let
    d = (dict lang).posts
    idNum = postId post
  in
    container "max-w-4xl" "py-16 sm:py-24 space-y-6"
      [ el "div" [ class_ "flex items-center justify-between" ]
          [ spaLink lang PostList
              [ class_ "btn btn-ghost btn-sm text-xs font-mono" ]
              [ el "span" [ attr "aria-hidden" "true" ] [ text "← " ]
              , text d.backToList
              ]
          ]
      , el "article" [ class_ "card bg-base-100 shadow-md border border-base-200" ]
          [ el "div" [ class_ "card-body p-8 sm:p-12 space-y-6" ]
              [ el "div" [ class_ "flex items-center gap-x-3 text-xs font-mono text-base-content/60" ]
                  [ el "span" [] [ text ("Article #" <> show idNum) ]
                  ]
              , el "h1" [ class_ "text-3xl sm:text-4xl font-extrabold tracking-tight text-base-content leading-tight capitalize" ]
                  [ text (postTitle post) ]
              , el "div" [ class_ "flex items-center gap-x-3.5 pb-6 border-b border-base-200" ]
                  [ el "div" [ class_ "avatar placeholder" ]
                      [ el "div" [ class_ "bg-primary text-primary-content rounded-md size-9 flex items-center justify-center font-mono font-bold text-sm" ]
                          [ el "span" [] [ text "P" ] ]
                      ]
                  , el "div" [ class_ "text-xs" ]
                      [ el "p" [ class_ "font-semibold text-base-content" ] [ text d.unknownAuthor ]
                      , el "p" [ class_ "text-base-content/60 font-mono text-[11px] uppercase" ] [ text "Engineering Team" ]
                      ]
                  ]
              , el "div" [ class_ "pt-2" ]
                  [ el "p" [ class_ "text-base sm:text-lg text-base-content/85 leading-relaxed font-normal whitespace-pre-line" ]
                      [ text (postBody post) ]
                  ]
              ]
          ]
      ]

-- | Error state — shown when the API fetch fails.
renderPostsError :: Lang -> Html
renderPostsError lang =
  let
    d = (dict lang).posts
  in
    container "max-w-3xl" "py-20 text-center space-y-6"
      [ el "h1" [ class_ "text-4xl font-extrabold text-base-content" ]
          [ text d.listTitle ]
      , Ui.alert Ui.AlertError d.loadingError
      ]

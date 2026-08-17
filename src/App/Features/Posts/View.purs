-- | Posts view — list and detail rendering
module App.Features.Posts.View where

import Prelude

import App.Alpine (spaLink)
import App.Features.Posts.Components.PostCard (renderPostCard)
import App.Features.Posts.Types (Post, postBody, postId, postTitle)
import App.Html (Html, attr, class_, el, text)
import App.Ui.Alert as Alert
import App.Ui.Badge as Badge
import App.Ui.Card (card, cardBody)
import App.Ui.Container (container)
import Data.Array (take)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

-- | Post list page — shows up to 9 posts with links to detail pages in a 3-column grid.
-- | Data is fetched in the Page module (Aff), passed in as a pure argument.
renderPostList :: Lang -> Array Post -> Html
renderPostList lang posts =
  let
    d = (dict lang).posts
    navDict = (dict lang).nav
  in
    container "max-w-7xl" "py-12 sm:py-16 lg:py-20"
      [ el "div" [ class_ "text-center max-w-2xl mx-auto mb-10 sm:mb-12" ]
          [ el "div" [ class_ "mb-4 flex justify-center" ]
              [ Badge.badge Badge.Neutral navDict.posts ]
          , el "h1" [ class_ "font-display text-4xl sm:text-5xl font-extrabold tracking-tight text-gray-900 dark:text-white leading-tight" ]
              [ text d.listTitle ]
          ]
      , el "div" [ class_ "grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3" ]
          [ foldMap (renderPostCard lang) (take 9 posts) ]
      ]

-- | Post detail page — shows a single post with a back link and rich layout.
renderPostDetail :: Lang -> Post -> Html
renderPostDetail lang post =
  let
    d = (dict lang).posts
    idNum = postId post
    categoryTag = case idNum `mod` 3 of
      0 -> "Performance"
      1 -> "Architecture"
      _ -> "Type Safety"
    categoryVariant = case idNum `mod` 3 of
      0 -> Badge.Primary
      1 -> Badge.Tertiary
      _ -> Badge.Secondary
    readTime = show (3 + (idNum `mod` 4)) <> " min read"
  in
    container "max-w-7xl" "py-12 sm:py-16 lg:py-20"
      [ el "div" [ class_ "max-w-4xl mx-auto" ]
          [ el "div" [ class_ "mb-8 flex items-center justify-between" ]
              [ spaLink lang PostList
                  [ class_ "inline-flex items-center gap-x-2 rounded-lg bg-base-100 px-3.5 py-1.5 text-xs font-mono font-medium text-base-content hover:bg-base-200 ring-1 ring-base-content/10 transition-colors" ]
                  [ el "span" [ attr "aria-hidden" "true" ] [ text "←" ]
                  , text d.backToList
                  ]
              ]
          , card $ cardBody
              ( el "article" [ class_ "p-4 sm:p-8" ]
                  [ el "div" [ class_ "flex items-center gap-x-3 text-xs mb-6" ]
                      [ Badge.badge categoryVariant categoryTag
                      , el "span" [ class_ "text-xs font-mono text-gray-500 dark:text-gray-400" ]
                          [ text readTime ]
                      , el "span" [ class_ "text-xs font-mono text-gray-400 dark:text-gray-500" ]
                          [ text ("• Note #" <> show idNum) ]
                      ]
                  , el "h1" [ class_ "font-display text-3xl font-extrabold tracking-tight text-gray-900 sm:text-5xl dark:text-white leading-tight capitalize" ]
                      [ text (postTitle post) ]
                  , el "div" [ class_ "mt-6 flex items-center gap-x-3.5 pb-8 border-b border-gray-100 dark:border-white/5" ]
                      [ el "div" [ class_ "size-10 rounded-full bg-gray-900 dark:bg-emerald-500/20 ring-1 ring-gray-800 dark:ring-emerald-400/30 flex items-center justify-center text-emerald-400 text-sm font-mono font-bold shadow-xs" ]
                          [ text "P" ]
                      , el "div" [ class_ "text-xs" ]
                          [ el "p" [ class_ "font-semibold text-gray-900 dark:text-white" ] [ text d.unknownAuthor ]
                          , el "p" [ class_ "text-gray-500 dark:text-gray-400 font-mono text-[11px]" ] [ text "Pohjola Engineering Team" ]
                          ]
                      ]
                  , el "div" [ class_ "mt-8" ]
                      [ el "p" [ class_ "text-lg/8 text-gray-700 dark:text-gray-300 leading-relaxed font-normal whitespace-pre-line" ]
                          [ text (postBody post) ]
                      ]
                  ]
              )
          ]
      ]

-- | Error state — shown when the API fetch fails.
renderPostsError :: Lang -> Html
renderPostsError lang =
  let
    d = (dict lang).posts
  in
    container "max-w-3xl" "py-16 sm:py-20 text-center"
      [ el "h1" [ class_ "font-display text-4xl font-extrabold text-gray-900 dark:text-white mb-6" ]
          [ text d.listTitle ]
      , Alert.alert Alert.Error d.loadingError
      ]


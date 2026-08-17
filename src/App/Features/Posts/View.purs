-- | Posts view — list and detail rendering via slot-based layout templates
module App.Features.Posts.View where

import Prelude

import App.Alpine (spaLink)
import App.Features.Posts.Components.PostCard (renderPostCard)
import App.Features.Posts.Types (Post, postBody, postId, postTitle)
import App.Html (Html, attr, class_, el, text)
import App.Ui.Alert as Alert
import App.Ui.Badge as Badge
import App.Ui.Container (container)
import App.Ui.Layout.Grid (grid3)
import App.Ui.Layout.SectionHeader (Align(..), sectionHeader)
import Data.Array (take)
import Data.Foldable (foldMap)
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
    container "max-w-5xl" "py-16 sm:py-24 space-y-12"
      [ sectionHeader
          { eyebrow: Just navDict.posts
          , title: d.listTitle
          , subtitle: Nothing
          , align: Left
          }
      , grid3 (map (renderPostCard lang) (take 9 posts))
      ]

-- | Post detail page — shows a single post with a back link and rich layout.
renderPostDetail :: Lang -> Post -> Html
renderPostDetail lang post =
  let
    d = (dict lang).posts
    idNum = postId post
    categoryTag = case idNum `mod` 3 of
      0 -> "PERFORMANCE"
      1 -> "ARCHITECTURE"
      _ -> "TYPE SAFETY"
    categoryVariant = case idNum `mod` 3 of
      0 -> Badge.Primary
      1 -> Badge.Tertiary
      _ -> Badge.Secondary
    readTime = show (3 + (idNum `mod` 4)) <> " MIN READ"
  in
    container "max-w-4xl" "py-16 sm:py-24 space-y-8"
      [ el "div" [ class_ "flex items-center justify-between" ]
          [ spaLink lang PostList
              [ class_ "inline-flex items-center gap-x-2 rounded-md bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 px-3.5 py-1.5 text-xs font-mono font-medium text-zinc-800 dark:text-zinc-200 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors shadow-2xs" ]
              [ el "span" [ attr "aria-hidden" "true" ] [ text "←" ]
              , text d.backToList
              ]
          ]
      , el "article" [ class_ "p-8 sm:p-12 rounded-lg bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-2xs space-y-8" ]
          [ el "div" [ class_ "flex items-center gap-x-3 text-xs mb-4" ]
              [ Badge.badge categoryVariant categoryTag
              , el "span" [ class_ "text-xs font-mono text-zinc-400" ]
                  [ text readTime ]
              , el "span" [ class_ "text-xs font-mono text-zinc-400" ]
                  [ text ("• ARCHIVE NOTE #" <> show idNum) ]
              ]
          , el "h1" [ class_ "font-display text-3xl sm:text-5xl font-extrabold tracking-tight text-zinc-950 dark:text-white leading-[1.1] capitalize" ]
              [ text (postTitle post) ]
          , el "div" [ class_ "flex items-center gap-x-3.5 pb-8 border-b border-zinc-100 dark:border-zinc-800" ]
              [ el "div" [ class_ "size-9 rounded-md bg-zinc-900 dark:bg-zinc-100 flex items-center justify-center text-emerald-400 dark:text-emerald-700 text-sm font-mono font-bold" ]
                  [ text "P" ]
              , el "div" [ class_ "text-xs" ]
                  [ el "p" [ class_ "font-semibold text-zinc-950 dark:text-white" ] [ text d.unknownAuthor ]
                  , el "p" [ class_ "text-zinc-400 font-mono text-[11px] uppercase" ] [ text "Pohjola Engineering Core" ]
                  ]
              ]
          , el "div" [ class_ "pt-2" ]
              [ el "p" [ class_ "text-lg sm:text-xl text-zinc-700 dark:text-zinc-300 leading-relaxed font-normal whitespace-pre-line" ]
                  [ text (postBody post) ]
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
      [ el "h1" [ class_ "font-display text-4xl font-extrabold text-zinc-950 dark:text-white" ]
          [ text d.listTitle ]
      , Alert.alert Alert.Error d.loadingError
      ]

-- | Post card — presentational component for a single post in a list.
module App.Features.Posts.Components.PostCard where

import Prelude

import App.Alpine (spaLink)
import App.Features.Posts.Types (Post, postBody, postId, postTitle)
import App.Html (Html, attr, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Card (card, cardBody)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

renderPostCard :: Lang -> Post -> Html
renderPostCard lang post =
  let
    d = (dict lang).posts
    idNum = postId post
    -- Category tags dynamically mapped by id
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
    card $ cardBody
      ( el "div" [ class_ "group relative flex flex-col justify-between h-full" ]
          [ el "div" []
              [ -- Header metadata row: category pill + read time indicator
                el "div" [ class_ "flex items-center justify-between text-xs" ]
                  [ Badge.badge categoryVariant categoryTag
                  , el "span" [ class_ "text-xs font-mono text-gray-500 dark:text-gray-400" ]
                      [ text readTime ]
                  ]
              -- Title & body
              , el "div" [ class_ "mt-4" ]
                  [ el "h2"
                      [ class_ "font-display text-lg font-bold tracking-tight text-gray-900 group-hover:text-emerald-700 dark:text-white dark:group-hover:text-emerald-400 transition-colors leading-snug" ]
                      [ spaLink lang (PostDetail idNum)
                          [ class_ "focus:outline-hidden" ]
                          [ el "span" [ class_ "absolute inset-0", attr "aria-hidden" "true" ] []
                          , text (postTitle post)
                          ]
                      ]
                  , el "p" [ class_ "mt-3 text-sm/6 text-gray-600 dark:text-gray-300 line-clamp-3 font-normal" ]
                      [ text (postBody post) ]
                  ]
              ]
          -- Footer: Author & Read link
          , el "div" [ class_ "mt-6 flex items-center justify-between pt-4 border-t border-gray-100 dark:border-white/5" ]
              [ el "div" [ class_ "flex items-center gap-x-2.5" ]
                  [ el "div" [ class_ "size-7 rounded-full bg-gray-900 dark:bg-emerald-500/20 ring-1 ring-gray-800 dark:ring-emerald-400/30 flex items-center justify-center text-emerald-400 text-xs font-mono font-bold shadow-xs" ]
                      [ text "P" ]
                  , el "div" [ class_ "text-xs leading-tight" ]
                      [ el "p" [ class_ "font-semibold text-gray-900 dark:text-white" ] [ text d.unknownAuthor ]
                      , el "p" [ class_ "text-[11px] font-mono text-gray-500 dark:text-gray-400" ] [ text "Technical Note" ]
                      ]
                  ]
              , el "div" [ class_ "flex items-center gap-x-1 text-xs font-semibold text-emerald-700 dark:text-emerald-400 group-hover:translate-x-0.5 transition-transform" ]
                  [ text d.readMore
                  , el "span" [ attr "aria-hidden" "true" ] [ text " →" ]
                  ]
              ]
          ]
      )


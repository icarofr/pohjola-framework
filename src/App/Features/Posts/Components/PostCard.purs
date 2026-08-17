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
      0 -> "PERFORMANCE"
      1 -> "ARCHITECTURE"
      _ -> "TYPE SAFETY"
    categoryVariant = case idNum `mod` 3 of
      0 -> Badge.Primary
      1 -> Badge.Tertiary
      _ -> Badge.Secondary
    readTime = show (3 + (idNum `mod` 4)) <> " MIN READ"
  in
    card $ cardBody
      ( el "div" [ class_ "group relative flex flex-col justify-between h-full space-y-6" ]
          [ el "div" []
              [ -- Header metadata row: category pill + read time indicator
                el "div" [ class_ "flex items-center justify-between text-xs" ]
                  [ Badge.badge categoryVariant categoryTag
                  , el "span" [ class_ "text-xs font-mono text-zinc-400" ]
                      [ text readTime ]
                  ]
              -- Title & body
              , el "div" [ class_ "mt-4" ]
                  [ el "h2"
                      [ class_ "font-display text-xl font-bold tracking-tight text-zinc-950 group-hover:text-emerald-700 dark:text-white dark:group-hover:text-emerald-400 transition-colors leading-snug" ]
                      [ spaLink lang (PostDetail idNum)
                          [ class_ "focus:outline-hidden" ]
                          [ el "span" [ class_ "absolute inset-0", attr "aria-hidden" "true" ] []
                          , text (postTitle post)
                          ]
                      ]
                  , el "p" [ class_ "mt-3 text-sm leading-relaxed text-zinc-600 dark:text-zinc-400 line-clamp-3 font-normal" ]
                      [ text (postBody post) ]
                  ]
              ]
          -- Footer: Author & Read link
          , el "div" [ class_ "flex items-center justify-between pt-4 border-t border-zinc-100 dark:border-zinc-800" ]
              [ el "div" [ class_ "flex items-center gap-x-2.5" ]
                  [ el "div" [ class_ "size-6 rounded-md bg-zinc-900 dark:bg-zinc-100 flex items-center justify-center text-emerald-400 dark:text-emerald-700 text-xs font-mono font-bold" ]
                      [ text "P" ]
                  , el "div" [ class_ "text-xs leading-tight" ]
                      [ el "p" [ class_ "font-semibold text-zinc-950 dark:text-white" ] [ text d.unknownAuthor ]
                      , el "p" [ class_ "text-[10px] font-mono text-zinc-400 uppercase" ] [ text "Technical Note" ]
                      ]
                  ]
              , el "div" [ class_ "flex items-center gap-x-1 text-xs font-mono font-semibold text-emerald-700 dark:text-emerald-400 group-hover:translate-x-0.5 transition-transform" ]
                  [ text d.readMore
                  , el "span" [ attr "aria-hidden" "true" ] [ text " →" ]
                  ]
              ]
          ]
      )

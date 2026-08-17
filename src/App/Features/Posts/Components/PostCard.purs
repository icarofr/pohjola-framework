-- | PostCard component — pure DaisyUI card component
module App.Features.Posts.Components.PostCard (renderPostCard) where

import Prelude

import App.Alpine (spaLink)
import App.Features.Posts.Types (Post, postBody, postId, postTitle)
import App.Html (Html, class_, el, text)
import App.Ui.Card (card, cardActions, cardBody, cardTitle)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

renderPostCard :: Lang -> Post -> Html
renderPostCard lang post =
  let
    d = (dict lang).posts
    idNum = postId post
  in
    card $ cardBody
      ( el "div" [ class_ "flex flex-col justify-between h-full space-y-4" ]
          [ el "div" [ class_ "space-y-3" ]
              [ el "div" [ class_ "flex items-center justify-between text-xs text-base-content/60 font-mono" ]
                  [ el "span" [] [ text ("Article #" <> show idNum) ]
                  ]
              , cardTitle (el "span" [ class_ "line-clamp-2 text-base font-bold text-base-content" ] [ text (postTitle post) ])
              , el "p" [ class_ "line-clamp-3 text-sm text-base-content/75 font-normal leading-relaxed" ]
                  [ text (postBody post) ]
              ]
          , cardActions
              ( spaLink lang (PostDetail idNum)
                  [ class_ "btn btn-outline btn-sm w-full font-semibold" ]
                  [ text (d.readMore <> " →") ]
              )
          ]
      )

-- | DaisyUI Card primitive
module App.Ui.Card where

import App.Html (Html, alt, class_, decoding_, el, height_, loading_, src, width_)

card :: Html -> Html
card inner =
  el "div" [ class_ "card bg-base-100 shadow-md border border-base-200" ] [ inner ]

cardBody :: Html -> Html
cardBody inner =
  el "div" [ class_ "card-body" ] [ inner ]

cardTitle :: Html -> Html
cardTitle inner =
  el "h3" [ class_ "card-title text-base-content" ] [ inner ]

cardActions :: Html -> Html
cardActions inner =
  el "div" [ class_ "card-actions justify-end mt-4" ] [ inner ]

cardImage :: { src :: String, alt :: String, width :: Int, height :: Int } -> Html
cardImage props =
  el "figure" [ class_ "aspect-16/10 overflow-hidden bg-base-200" ]
    [ el "img"
        [ src props.src
        , alt props.alt
        , width_ props.width
        , height_ props.height
        , loading_ "lazy"
        , decoding_ "async"
        , class_ "h-full w-full object-cover"
        ]
        []
    ]

-- | Card primitive — Tailwind UI container
module App.Ui.Card where

import App.Html (Html, alt, class_, el, height_, loading_, decoding_, src, width_)
import Data.Content (Image)

-- | Render a card wrapper around content
card :: Html -> Html
card inner =
  el "div"
    [ class_ "flex flex-col overflow-hidden rounded-2xl bg-white shadow-xs ring-1 ring-gray-200 hover:ring-gray-300 dark:bg-gray-800/50 dark:shadow-none dark:ring-white/10 transition-all hover:shadow-md dark:hover:ring-white/20" ]
    [ inner ]

-- | Card image section
cardImage :: Image -> Html
cardImage props =
  el "div" [ class_ "relative overflow-hidden aspect-16/10 bg-gray-100 dark:bg-gray-800" ]
    [ el "img"
        [ class_ "h-full w-full object-cover transition-transform duration-300 hover:scale-105"
        , src props.url
        , alt props.alt
        , width_ props.width
        , height_ props.height
        , loading_ "lazy"
        , decoding_ "async"
        ]
        []
    ]

-- | Card body section
cardBody :: Html -> Html
cardBody inner =
  el "div" [ class_ "flex flex-1 flex-col justify-between p-6 sm:p-7" ] [ inner ]

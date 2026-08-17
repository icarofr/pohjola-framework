-- | Card primitive — Nordic Architectural container with razor-sharp hairline borders
module App.Ui.Card where

import Prelude

import App.Html (Html, alt, class_, decoding_, el, height_, loading_, src, width_)
import Data.Content (Image)

-- | Render a card wrapper around content
card :: Html -> Html
card inner =
  el "div"
    [ class_ "flex flex-col overflow-hidden rounded-lg bg-white dark:bg-zinc-900 border border-zinc-200/90 dark:border-zinc-800 shadow-2xs transition-all hover:border-zinc-300 dark:hover:border-zinc-700" ]
    [ inner ]

-- | Card image section
cardImage :: Image -> Html
cardImage props =
  el "div" [ class_ "relative overflow-hidden aspect-16/10 bg-zinc-100 dark:bg-zinc-800 border-b border-zinc-200/80 dark:border-zinc-800" ]
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

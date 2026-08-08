-- | Card primitive — shadcn-inspired container
module App.Ui.Card where

import App.Html (Html, alt, class_, el, height_, loading_, decoding_, src, width_)
import Data.Content (Image)

-- | Render a card wrapper around content
card :: Html -> Html
card inner =
  el "div"
    [ class_ "flex flex-col overflow-hidden rounded-2xl shadow-lg ring-1 ring-gray-200 dark:ring-slate-700 bg-white dark:bg-slate-800" ]
    [ inner ]

-- | Card image section
cardImage :: Image -> Html
cardImage props =
  el "div" [ class_ "flex-shrink-0" ]
    [ el "img"
        [ class_ "h-48 w-full object-cover"
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
  el "div" [ class_ "flex flex-1 flex-col justify-between p-6" ] [ inner ]

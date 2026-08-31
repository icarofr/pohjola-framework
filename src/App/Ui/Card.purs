-- | DaisyUI card — vendor/daisyui/skills/daisyui/components/card.md
module App.Ui.Card
  ( CardSize(..)
  , CardOptions
  , defaultCardOptions
  , card
  , cardBody
  , cardTitle
  , cardHeading
  , cardText
  , cardActions
  , cardFigure
  , cardImage
  ) where

import Prelude

import App.Html (Html, alt, class_, decoding_, el, height_, loading_, src, text, width_)
import Data.Maybe (Maybe(..))

data CardSize = CardXs | CardSm | CardMd | CardLg | CardXl

type CardOptions =
  { border :: Boolean
  , shadow :: Boolean
  , size :: Maybe CardSize
  , fullHeight :: Boolean
  }

defaultCardOptions :: CardOptions
defaultCardOptions =
  { border: true
  , shadow: false
  , size: Nothing
  , fullHeight: true
  }

cardClass :: CardOptions -> String
cardClass opts =
  let
    base = "card bg-base-100"
    border = if opts.border then " card-border" else ""
    shadow = if opts.shadow then " shadow-sm" else ""
    size =
      case opts.size of
        Just CardXs -> " card-xs"
        Just CardSm -> " card-sm"
        Just CardMd -> " card-md"
        Just CardLg -> " card-lg"
        Just CardXl -> " card-xl"
        Nothing -> ""
    height = if opts.fullHeight then " h-full" else ""
  in
    base <> border <> shadow <> size <> height

-- | DaisyUI card wrapper
card :: CardOptions -> Array Html -> Html
card opts children =
  el "div" [ class_ (cardClass opts) ] children

-- | DaisyUI card-body (flex col, gap, padding via CSS vars)
cardBody :: Array Html -> Html
cardBody children =
  el "div" [ class_ "card-body" ] children

-- | DaisyUI card-title (h2)
cardTitle :: String -> Html
cardTitle title =
  el "h2" [ class_ "card-title" ] [ text title ]

-- | Article/detail heading with card-title styling
cardHeading :: String -> Html
cardHeading title =
  el "h1" [ class_ "card-title" ] [ text title ]

-- | Body copy — card-body styles paragraphs
cardText :: String -> Html
cardText copy =
  el "p" [] [ text copy ]

-- | DaisyUI card-actions
cardActions :: Boolean -> Array Html -> Html
cardActions end actions =
  let
    justify = if end then " justify-end" else ""
  in
    el "div" [ class_ ("card-actions" <> justify) ] actions

-- | DaisyUI card figure slot
cardFigure :: Html -> Html
cardFigure inner =
  el "figure" [] [ inner ]

cardImage :: { src :: String, alt :: String, width :: Int, height :: Int } -> Html
cardImage props =
  el "img"
    [ src props.src
    , alt props.alt
    , width_ props.width
    , height_ props.height
    , loading_ "lazy"
    , decoding_ "async"
    ]
    []

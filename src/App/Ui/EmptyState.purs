-- | DaisyUI EmptyState primitive
module App.Ui.EmptyState where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.TextTone (TextTone(..), toneClass)
import Data.Maybe (Maybe(..))

type EmptyStateProps =
  { title :: String
  , description :: String
  , action :: Maybe Html
  }

emptyState :: EmptyStateProps -> Html
emptyState props =
  el "div" [ class_ "hero bg-base-200 rounded-box p-8 text-center border border-base-300" ]
    [ el "div" [ class_ "hero-content flex-col max-w-md space-y-4" ]
        [ el "h3" [ class_ "text-xl font-bold text-base-content" ] [ text props.title ]
        , el "p" [ class_ ("text-sm " <> toneClass Copy) ] [ text props.description ]
        , case props.action of
            Just act -> el "div" [ class_ "pt-2" ] [ act ]
            Nothing -> text ""
        ]
    ]

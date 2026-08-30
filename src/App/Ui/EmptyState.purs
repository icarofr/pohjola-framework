-- | DaisyUI empty state — frozen centered card recipe (no hero slab)
module App.Ui.EmptyState
  ( EmptyStateProps
  , emptyState
  , emptyStateCardClass
  , emptyStateSectionClass
  ) where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.TextTone (TextTone(..), toneClass)
import Data.Maybe (Maybe(..))

type EmptyStateProps =
  { title :: String
  , description :: String
  , action :: Maybe Html
  }

-- | Frozen class recipes — do not vary per feature (eval 07 / UiSpec).
emptyStateSectionClass :: String
emptyStateSectionClass = "py-16 sm:py-20"

emptyStateCardClass :: String
emptyStateCardClass = "card bg-base-100 card-border max-w-lg mx-auto text-center"

emptyStateTitleClass :: String
emptyStateTitleClass = "card-title justify-center text-2xl"

emptyState :: EmptyStateProps -> Html
emptyState props =
  el "section" [ class_ emptyStateSectionClass ]
    [ el "div" [ class_ emptyStateCardClass ]
        [ el "div" [ class_ "card-body items-center" ]
            ( [ el "h3" [ class_ emptyStateTitleClass ] [ text props.title ]
              , el "p" [ class_ ("text-base " <> toneClass Copy) ] [ text props.description ]
              , case props.action of
                  Just act -> el "div" [ class_ "card-actions justify-center" ] [ act ]
                  Nothing -> text ""
              ]
            )
        ]
    ]

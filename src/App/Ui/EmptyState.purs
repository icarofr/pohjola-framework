-- | Empty state primitive — Actionable empty state conforming to Layr guidelines
module App.Ui.EmptyState where

import App.Html (Html, class_, el, text)
import Data.Maybe (Maybe(..))

type EmptyStateProps =
  { title :: String
  , description :: String
  , action :: Maybe Html
  }

-- | Render an empty state card with guidance and optional CTA
emptyState :: EmptyStateProps -> Html
emptyState props =
  el "div" [ class_ "flex flex-col items-center justify-center p-8 text-center bg-base-100 rounded-lg ring-1 ring-base-content/10" ]
    [ el "h3" [ class_ "text-lg font-semibold text-base-content" ] [ text props.title ]
    , el "p" [ class_ "mt-1 text-sm text-base-content/70 max-w-sm" ] [ text props.description ]
    , case props.action of
        Just cta -> el "div" [ class_ "mt-5" ] [ cta ]
        Nothing -> text ""
    ]

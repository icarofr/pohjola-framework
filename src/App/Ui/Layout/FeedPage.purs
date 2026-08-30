-- | Feed page — list archetype with optional empty state
module App.Ui.Layout.FeedPage
  ( FeedPageBlueprint
  , feedPage
  , feedPageContainerClass
  ) where

import App.Html (Html, text)
import App.Ui.EmptyState (EmptyStateProps, emptyState)
import App.Ui.Layout.Grid (grid3)
import App.Ui.Layout.PageSection (pageSection)
import App.Ui.Layout.SectionHeader (Align(..))
import Data.Array (null)
import Data.Maybe (Maybe(..))

type FeedPageBlueprint =
  { category :: Maybe String
  , title :: String
  , subtitle :: Maybe String
  , items :: Array Html
  , empty :: Maybe EmptyStateProps
  }

feedPageContainerClass :: String
feedPageContainerClass = "py-16 sm:py-24"

feedPage :: FeedPageBlueprint -> Html
feedPage page =
  pageSection
    { header:
        { eyebrow: page.category
        , title: page.title
        , subtitle: page.subtitle
        , align: Left
        }
    , content:
        if null page.items then
          case page.empty of
            Just props -> emptyState props
            Nothing -> text ""
        else
          grid3 page.items
    , banded: false
    }

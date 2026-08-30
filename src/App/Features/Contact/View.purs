-- | Community & Contributing — hub page archetype
module App.Features.Contact.View where

import Prelude

import App.Html (Html)
import App.Ui as Ui
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))

renderContact :: Lang -> Html
renderContact lang =
  let
    d = (dict lang).contact
    navDict = (dict lang).nav
  in
    Ui.hubPage
      { category: Just navDict.contact
      , title: d.title
      , subtitle: Just d.subtitle
      , cards:
          [ { tag: Just { text: d.issuesTag, variant: Ui.BadgeError }
            , imageUrl: Nothing
            , title: d.issuesTitle
            , description: d.issuesText
            , action: { label: d.issuesButton <> " →", target: Ui.External { href: "https://github.com/icarofr/pohjola-framework/issues" } }
            }
          , { tag: Just { text: d.discussionsTag, variant: Ui.BadgeTertiary }
            , imageUrl: Nothing
            , title: d.discussionsTitle
            , description: d.discussionsText
            , action: { label: d.discussionsButton <> " →", target: Ui.External { href: "https://github.com/icarofr/pohjola-framework/discussions" } }
            }
          , { tag: Just { text: d.sourceTag, variant: Ui.BadgePrimary }
            , imageUrl: Nothing
            , title: d.sourceTitle
            , description: d.sourceText
            , action: { label: d.sourceButton <> " →", target: Ui.External { href: "https://github.com/icarofr/pohjola-framework" } }
            }
          ]
      }

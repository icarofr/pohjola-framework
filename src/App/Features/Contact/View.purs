-- | Community & Contributing page — strictly assembled via rigid App.Ui component contracts
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
    Ui.pageLayout
      { header:
          Ui.pageHeader
            { category: Just navDict.contact
            , title: d.title
            , subtitle: Just d.subtitle
            }
      , content:
          Ui.grid3
            [ Ui.actionCard
                { tag: Just { text: "Issues", variant: Ui.BadgeError }
                , imageUrl: Nothing
                , title: d.issuesTitle
                , description: d.issuesText
                , action: { label: d.issuesButton <> " →", target: Ui.External { href: "https://github.com/icarofr/pohjola-framework/issues" } }
                }
            , Ui.actionCard
                { tag: Just { text: "Community", variant: Ui.BadgeTertiary }
                , imageUrl: Nothing
                , title: d.discussionsTitle
                , description: d.discussionsText
                , action: { label: d.discussionsButton <> " →", target: Ui.External { href: "https://github.com/icarofr/pohjola-framework/discussions" } }
                }
            , Ui.actionCard
                { tag: Just { text: "Source", variant: Ui.BadgePrimary }
                , imageUrl: Nothing
                , title: d.sourceTitle
                , description: d.sourceText
                , action: { label: d.sourceButton <> " →", target: Ui.External { href: "https://github.com/icarofr/pohjola-framework" } }
                }
            ]
      }

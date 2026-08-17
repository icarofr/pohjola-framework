-- | Community & Contributing page — built via rigid slot-based layout templates
module App.Features.Contact.View where

import Prelude

import App.Html (Html)
import App.Ui.Badge as Badge
import App.Ui.Container (container)
import App.Ui.Layout.ActionCard (actionCard)
import App.Ui.Layout.Grid (grid3)
import App.Ui.Layout.SectionHeader (Align(..), sectionHeader)
import App.Ui.Layout.Types (ActionTarget(..))
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))

renderContact :: Lang -> Html
renderContact lang =
  let
    d = (dict lang).contact
    navDict = (dict lang).nav
  in
    container "max-w-5xl" "py-16 sm:py-24 space-y-12"
      [ sectionHeader
          { eyebrow: Just navDict.contact
          , title: d.title
          , subtitle: Just d.subtitle
          , align: Left
          }
      , grid3
          [ actionCard
              { tag: Just { text: "TRIAGE < 24H", variant: Badge.Error }
              , imageUrl: Nothing
              , title: d.issuesTitle
              , description: d.issuesText
              , action: { label: d.issuesButton <> " →", target: External { href: "https://github.com/icarofr/pohjola-framework/issues" } }
              }
          , actionCard
              { tag: Just { text: "OPEN RFC", variant: Badge.Tertiary }
              , imageUrl: Nothing
              , title: d.discussionsTitle
              , description: d.discussionsText
              , action: { label: d.discussionsButton <> " →", target: External { href: "https://github.com/icarofr/pohjola-framework/discussions" } }
              }
          , actionCard
              { tag: Just { text: "MIT LICENSE", variant: Badge.Primary }
              , imageUrl: Nothing
              , title: d.sourceTitle
              , description: d.sourceText
              , action: { label: d.sourceButton <> " →", target: External { href: "https://github.com/icarofr/pohjola-framework" } }
              }
          ]
      ]

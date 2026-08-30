-- | Editorial page — pageSection + prose-lg
module App.Ui.Layout.EditorialPage
  ( EditorialPageBlueprint
  , editorialPage
  , editorialParagraphs
  , editorialContentClass
  ) where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Button (ButtonVariant, Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Divider as Divider
import App.Ui.Layout.PageSection (pageSection)
import App.Ui.Layout.SectionHeader (Align(..))
import App.Ui.Layout.Types (ActionTarget(..))
import App.Ui.Prose (proseLg)
import Data.Maybe (Maybe(..))

editorialParagraphs :: Array String -> Html
editorialParagraphs paragraphs =
  proseLg (map (\p -> el "p" [] [ text p ]) paragraphs)

editorialContentClass :: String
editorialContentClass = "space-y-8 max-w-3xl"

type EditorialPageBlueprint =
  { category :: Maybe String
  , title :: String
  , subtitle :: Maybe String
  , body :: Html
  , action :: Maybe { label :: String, variant :: ButtonVariant, target :: ActionTarget }
  }

editorialPage :: EditorialPageBlueprint -> Html
editorialPage page =
  pageSection
    { header:
        { eyebrow: page.category
        , title: page.title
        , subtitle: page.subtitle
        , align: Left
        }
    , content:
        el "div" [ class_ editorialContentClass ]
          ( [ page.body
            , case page.action of
                Just act ->
                  el "div" [ class_ "space-y-6 not-prose" ]
                    [ Divider.divider
                    , case act.target of
                        Internal t ->
                          buttonLink { variant: act.variant, size: Lg, lang: t.lang, route: t.route } act.label
                        External t ->
                          buttonLinkExternal { variant: act.variant, size: Lg, href: t.href } act.label
                    ]
                Nothing -> text ""
            ]
          )
    , banded: false
    }

-- | Closed Editorial Page Blueprint — enforces typography, reading rhythm, and article geometry
module App.Ui.Layout.EditorialPage
  ( EditorialPageBlueprint
  , editorialPage
  ) where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Button (ButtonVariant, Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Container (container)
import App.Ui.Layout.SectionHeader (Align(..), sectionHeader)
import App.Ui.Layout.Types (ActionTarget(..))
import App.Ui.TextTone (TextTone(..), toneClass)
import Data.Maybe (Maybe(..))

type EditorialPageBlueprint =
  { category :: Maybe String
  , title :: String
  , subtitle :: Maybe String
  , body :: Html
  , action :: Maybe { label :: String, variant :: ButtonVariant, target :: ActionTarget }
  }

-- | Render an editorial document page blueprint
editorialPage :: EditorialPageBlueprint -> Html
editorialPage page =
  container "max-w-4xl" "py-16 sm:py-24 space-y-12"
    [ sectionHeader
        { eyebrow: page.category
        , title: page.title
        , subtitle: page.subtitle
        , align: Center
        }
    , el "div" [ class_ "card bg-base-100 shadow-md border border-base-200" ]
        [ el "div" [ class_ ("card-body p-8 sm:p-10 space-y-6 text-base sm:text-lg leading-relaxed font-normal " <> toneClass Copy) ]
            [ page.body ]
        ]
    , case page.action of
        Just act ->
          el "div" [ class_ "flex justify-end pt-2" ]
            [ case act.target of
                Internal t -> buttonLink { variant: act.variant, size: Lg, lang: t.lang, route: t.route, extraClass: "shadow-sm" } act.label
                External t -> buttonLinkExternal { variant: act.variant, size: Lg, href: t.href, extraClass: "shadow-sm" } act.label
            ]
        Nothing -> text ""
    ]

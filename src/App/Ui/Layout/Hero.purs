-- | Rigid Hero section template using DaisyUI semantic hero classes
module App.Ui.Layout.Hero where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Badge (BadgeVariant(..))
import App.Ui.Badge as Badge
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Layout.Types (ActionTarget(..))
import Data.Maybe (Maybe(..))

type HeroAction =
  { label :: String
  , target :: ActionTarget
  }

type HeroProps =
  { eyebrow :: Maybe String
  , title :: String
  , body :: String
  , primaryAction :: HeroAction
  , secondaryAction :: Maybe HeroAction
  }

-- | Render a Hero section with DaisyUI hero semantics
hero :: HeroProps -> Html
hero props =
  el "section" [ class_ "hero bg-base-200 py-16 sm:py-24 border-b border-base-300" ]
    [ el "div" [ class_ "hero-content text-center max-w-4xl flex-col space-y-6" ]
        [ case props.eyebrow of
            Just eb -> Badge.badge BadgePrimary eb
            Nothing -> text ""
        , el "h1" [ class_ "text-4xl sm:text-6xl font-black tracking-tight leading-tight text-base-content" ]
            [ text props.title ]
        , el "p" [ class_ "text-lg sm:text-xl text-base-content/80 max-w-2xl mx-auto leading-relaxed" ]
            [ text props.body ]
        , el "div" [ class_ "flex flex-wrap items-center justify-center gap-4 pt-2" ]
            [ renderHeroButton ButtonPrimary props.primaryAction
            , case props.secondaryAction of
                Just sec -> renderHeroButton ButtonOutline sec
                Nothing -> text ""
            ]
        ]
    ]

renderHeroButton :: ButtonVariant -> HeroAction -> Html
renderHeroButton variant action =
  case action.target of
    Internal t ->
      buttonLink { variant, size: Lg, lang: t.lang, route: t.route, extraClass: "" } action.label
    External t ->
      buttonLinkExternal { variant, size: Lg, href: t.href, extraClass: "" } action.label

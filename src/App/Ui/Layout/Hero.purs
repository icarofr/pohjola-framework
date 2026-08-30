-- | Landing hero — frozen DaisyUI recipe (research/daisyui hero + DESIGN.md)
module App.Ui.Layout.Hero
  ( HeroAction
  , HeroProps
  , hero
  ) where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Badge (BadgeVariant(..))
import App.Ui.Badge as Badge
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Layout.Types (ActionTarget(..))
import App.Ui.TextTone (TextTone(..), toneClass)
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

-- | Frozen class recipe — do not vary per feature (eval 07 / UiSpec).
heroSectionClass :: String
heroSectionClass = "hero bg-base-100 border-b border-base-300 min-h-0 py-20 sm:py-28"

heroContentClass :: String
heroContentClass = "hero-content text-center"

heroInnerClass :: String
heroInnerClass = "max-w-3xl"

heroTitleClass :: String
heroTitleClass = "text-4xl sm:text-5xl font-extrabold tracking-tight leading-tight"

heroBodyClass :: String
heroBodyClass = "text-lg py-6 " <> toneClass Copy

heroActionsClass :: String
heroActionsClass = "flex flex-wrap justify-center gap-3"

hero :: HeroProps -> Html
hero props =
  el "section" [ class_ heroSectionClass ]
    [ el "div" [ class_ heroContentClass ]
        [ el "div" [ class_ heroInnerClass ]
            ( [ case props.eyebrow of
                  Just eb -> Badge.badge BadgeTertiary eb
                  Nothing -> text ""
              , el "h1" [ class_ heroTitleClass ] [ text props.title ]
              , el "p" [ class_ heroBodyClass ] [ text props.body ]
              , el "div" [ class_ heroActionsClass ]
                  ( [ renderHeroButton ButtonPrimary props.primaryAction
                    , case props.secondaryAction of
                        Just sec -> renderHeroButton ButtonOutline sec
                        Nothing -> text ""
                    ]
                  )
              ]
            )
        ]
    ]

renderHeroButton :: ButtonVariant -> HeroAction -> Html
renderHeroButton variant action =
  case action.target of
    Internal t ->
      buttonLink { variant, size: Lg, lang: t.lang, route: t.route } action.label
    External t ->
      buttonLinkExternal { variant, size: Lg, href: t.href } action.label

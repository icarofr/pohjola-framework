-- | Rigid Hero section template with slot constraints
module App.Ui.Layout.Hero where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Badge (BadgeVariant(..))
import App.Ui.Badge as Badge
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Container (container)
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

-- | Render a Hero section with guaranteed typography hierarchy and button rhythm
hero :: HeroProps -> Html
hero props =
  el "section" [ class_ "py-20 sm:py-28 lg:py-32 border-b border-zinc-200 dark:border-zinc-800" ]
    [ container "max-w-5xl" "space-y-8"
        [ case props.eyebrow of
            Just eb -> Badge.badge BadgePrimary eb
            Nothing -> text ""
        , el "h1" [ class_ "font-display text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-zinc-950 dark:text-white leading-[1.05]" ]
            [ text props.title ]
        , el "p" [ class_ "text-lg sm:text-xl text-zinc-600 dark:text-zinc-300 max-w-2xl font-normal leading-relaxed" ]
            [ text props.body ]
        , el "div" [ class_ "flex flex-wrap items-center gap-4 pt-2" ]
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
      buttonLink { variant, size: Lg, lang: t.lang, route: t.route, extraClass: "px-6 py-3" } action.label
    External t ->
      buttonLinkExternal { variant, size: Lg, href: t.href, extraClass: "px-6 py-3" } action.label

-- | Pure DaisyUI Conversion CTA banner layout template
module App.Ui.Layout.ConversionCta where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Layout.Types (ActionTarget(..))

type ConversionCtaProps =
  { heading :: String
  , body :: String
  , action ::
      { label :: String
      , target :: ActionTarget
      }
  }

-- | Render a high-contrast conversion CTA banner using DaisyUI neutral hero
conversionCta :: ConversionCtaProps -> Html
conversionCta props =
  el "section" [ class_ "hero bg-neutral text-neutral-content py-16 sm:py-20 border-t border-neutral-content/10" ]
    [ el "div" [ class_ "hero-content text-center max-w-2xl flex-col space-y-6" ]
        [ el "h2" [ class_ "text-3xl sm:text-4xl font-extrabold tracking-tight leading-tight text-neutral-content" ]
            [ text props.heading ]
        , el "p" [ class_ "text-base sm:text-lg text-neutral-content/80 max-w-xl mx-auto leading-relaxed" ]
            [ text props.body ]
        , el "div" [ class_ "pt-2 flex justify-center" ]
            [ case props.action.target of
                Internal t ->
                  buttonLink { variant: ButtonInverted, size: Lg, lang: t.lang, route: t.route, extraClass: "shadow-md px-8" } props.action.label
                External t ->
                  buttonLinkExternal { variant: ButtonInverted, size: Lg, href: t.href, extraClass: "shadow-md px-8" } props.action.label
            ]
        ]
    ]

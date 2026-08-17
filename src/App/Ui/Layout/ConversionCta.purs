-- | Pure DaisyUI Conversion CTA banner layout template — unboxed, clean editorial section
module App.Ui.Layout.ConversionCta where

import App.Html (Html, class_, el, text)
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Container (container)
import App.Ui.Layout.Types (ActionTarget(..))

type ConversionCtaProps =
  { heading :: String
  , body :: String
  , action ::
      { label :: String
      , target :: ActionTarget
      }
  }

-- | Render a clean, unboxed conversion CTA section with generous breathing room
conversionCta :: ConversionCtaProps -> Html
conversionCta props =
  el "section" [ class_ "py-20 sm:py-28 bg-base-200/50 border-t border-base-300" ]
    [ container "max-w-3xl" "text-center space-y-6"
        [ el "h2" [ class_ "text-3xl sm:text-4xl font-extrabold tracking-tight text-base-content leading-tight" ]
            [ text props.heading ]
        , el "p" [ class_ "text-base sm:text-lg text-base-content/75 max-w-xl mx-auto leading-relaxed font-normal" ]
            [ text props.body ]
        , el "div" [ class_ "pt-3 flex justify-center" ]
            [ case props.action.target of
                Internal t ->
                  buttonLink { variant: ButtonPrimary, size: Lg, lang: t.lang, route: t.route, extraClass: "shadow-sm px-8" } props.action.label
                External t ->
                  buttonLinkExternal { variant: ButtonPrimary, size: Lg, href: t.href, extraClass: "shadow-sm px-8" } props.action.label
            ]
        ]
    ]

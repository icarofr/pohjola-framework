-- | Pure DaisyUI Conversion CTA banner layout template
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

-- | Render an elevated conversion CTA card using DaisyUI card styling
conversionCta :: ConversionCtaProps -> Html
conversionCta props =
  el "section" [ class_ "py-16 sm:py-24 bg-base-200/40 border-t border-base-300" ]
    [ container "max-w-4xl" ""
        [ el "div" [ class_ "card bg-base-100 shadow-xl border border-base-300 p-8 sm:p-12 text-center space-y-6 hover:border-primary/40 transition-colors" ]
            [ el "h2" [ class_ "text-3xl sm:text-4xl font-extrabold tracking-tight text-base-content leading-tight" ]
                [ text props.heading ]
            , el "p" [ class_ "text-base sm:text-lg text-base-content/75 max-w-xl mx-auto leading-relaxed font-normal" ]
                [ text props.body ]
            , el "div" [ class_ "pt-2 flex justify-center" ]
                [ case props.action.target of
                    Internal t ->
                      buttonLink { variant: ButtonPrimary, size: Lg, lang: t.lang, route: t.route, extraClass: "shadow-lg hover:shadow-primary/25 hover:scale-[1.01] transition-all px-8" } props.action.label
                    External t ->
                      buttonLinkExternal { variant: ButtonPrimary, size: Lg, href: t.href, extraClass: "shadow-lg hover:shadow-primary/25 hover:scale-[1.01] transition-all px-8" } props.action.label
                ]
            ]
        ]
    ]

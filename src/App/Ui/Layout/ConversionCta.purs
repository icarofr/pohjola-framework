-- | Rigid Conversion CTA banner layout template with slot constraints
module App.Ui.Layout.ConversionCta where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Button (buttonLink, buttonLinkExternal, Variant(..), Size(..))
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

-- | Render a high-contrast conversion CTA banner with guaranteed spacing
conversionCta :: ConversionCtaProps -> Html
conversionCta props =
  el "section" [ class_ "py-20 sm:py-28 bg-zinc-900 text-white border-t border-zinc-800" ]
    [ container "max-w-4xl" "text-center space-y-6"
        [ el "h2" [ class_ "font-display text-3xl sm:text-5xl font-extrabold tracking-tight text-white leading-tight" ]
            [ text props.heading ]
        , el "p" [ class_ "text-lg text-zinc-400 max-w-xl mx-auto font-normal leading-relaxed" ]
            [ text props.body ]
        , el "div" [ class_ "pt-4 flex justify-center" ]
            [ case props.action.target of
                Internal t ->
                  buttonLink { variant: Inverted, size: Lg, lang: t.lang, route: t.route, extraClass: "px-8 py-3.5 text-base font-bold shadow-lg" } props.action.label
                External t ->
                  buttonLinkExternal { variant: Inverted, size: Lg, href: t.href, extraClass: "px-8 py-3.5 text-base font-bold shadow-lg" } props.action.label
            ]
        ]
    ]

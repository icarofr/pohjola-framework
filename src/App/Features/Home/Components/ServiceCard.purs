-- | Service card — presentational component for a single service in the grid.
module App.Features.Home.Components.ServiceCard where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Button (buttonLinkExternal, Variant(..), Size(..))
import App.Ui.Card (card, cardImage, cardBody)
import Data.Content (Service, bookingUrl, formatPrice)
import Data.I18n (Lang, dict, langTag)

renderServiceCard :: Lang -> Service -> Html
renderServiceCard lang service =
  let
    d = (dict lang).services
    copy = d.serviceCopy service.id
  in
    card $
      cardImage { url: service.imageUrl, alt: copy.title, width: service.imageWidth, height: service.imageHeight }
        <> cardBody
          ( el "div" [ class_ "flex flex-col justify-between h-full" ]
              [ el "div" []
                  [ el "h3" [ class_ "font-display text-lg font-bold text-zinc-950 dark:text-white" ] [ text copy.title ]
                  , el "p" [ class_ "mt-2.5 text-sm leading-relaxed text-zinc-600 dark:text-zinc-400 font-normal" ] [ text copy.description ]
                  ]
              , el "div" [ class_ "mt-6 flex items-center justify-between pt-4 border-t border-zinc-100 dark:border-zinc-800" ]
                  [ Badge.badge Badge.Secondary (formatPrice (langTag lang) service.price)
                  , buttonLinkExternal { variant: Outline, size: Sm, href: bookingUrl, extraClass: "" } d.bookButton
                  ]
              ]
          )

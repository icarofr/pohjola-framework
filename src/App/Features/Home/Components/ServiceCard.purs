-- | Service card — presentational component for a single service in the grid.
module App.Features.Home.Components.ServiceCard where

import Prelude

import App.Html (Html, class_, el, text)
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
          ( el "div" [ class_ "flex-1" ]
              [ el "h3" [ class_ "font-display text-lg font-bold text-gray-900 dark:text-white" ] [ text copy.title ]
              , el "p" [ class_ "mt-2 text-sm/6 text-gray-600 dark:text-gray-400" ] [ text copy.description ]
              ]
              <> el "div" [ class_ "mt-6 flex items-center justify-between pt-4 border-t border-gray-100 dark:border-white/5" ]
                [ el "span" [ class_ "inline-flex items-center rounded-md bg-emerald-50 px-2.5 py-1 text-sm font-semibold text-emerald-700 ring-1 ring-inset ring-emerald-700/10 dark:bg-emerald-500/10 dark:text-emerald-400 dark:ring-emerald-400/30" ]
                    [ text (formatPrice (langTag lang) service.price) ]
                , buttonLinkExternal { variant: Primary, size: Sm, href: bookingUrl, extraClass: "" } d.bookButton
                ]
          )

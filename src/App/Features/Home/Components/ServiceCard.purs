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
              [ el "h3" [ class_ "font-display text-xl font-semibold text-slate-900 dark:text-white" ] [ text copy.title ]
              , el "p" [ class_ "mt-3 text-sm text-slate-600 dark:text-slate-400" ] [ text copy.description ]
              ]
              <> el "div" [ class_ "mt-6 flex items-center justify-between" ]
                [ el "span" [ class_ "text-2xl font-bold text-blue-600 dark:text-blue-400" ] [ text (formatPrice (langTag lang) service.price) ]
                , buttonLinkExternal { variant: Primary, size: Sm, href: bookingUrl, extraClass: "" } d.bookButton
                ]
          )

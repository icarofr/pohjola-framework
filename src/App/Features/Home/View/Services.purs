-- | Services section — grid of service cards
-- |
-- | Card metadata (price, image) comes from Data.Content; localized copy comes
-- | from the Dictionary via serviceCopy — one source of truth per concern.
module App.Features.Home.View.Services where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Button (buttonLinkExternal, Variant(..), Size(..))
import App.Ui.Card (card, cardImage, cardBody)
import Data.Content (Service, bookingUrl, formatPrice, services)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict, langTag)

renderServices :: Lang -> Html
renderServices lang =
  let
    d = (dict lang).services
  in
    el "section" [ class_ "py-20 bg-white dark:bg-slate-950" ]
      [ el "div" [ class_ "mx-auto max-w-7xl px-4 sm:px-6 lg:px-8" ]
          [ el "div" [ class_ "mx-auto max-w-2xl text-center" ]
              [ el "h2" [ class_ "font-display text-3xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-4xl" ]
                  [ text d.sectionTitle ]
              ]
          , el "div" [ class_ "mx-auto mt-16 grid max-w-2xl grid-cols-1 gap-x-8 gap-y-16 sm:mt-20 lg:mx-0 lg:max-w-none lg:grid-cols-3" ]
              [ foldMap (renderServiceCard lang) services ]
          ]
      ]

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

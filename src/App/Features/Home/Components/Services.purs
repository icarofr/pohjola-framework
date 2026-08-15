-- | Services section — grid of service cards
-- |
-- | Card metadata (price, image) comes from Data.Content; localized copy comes
-- | from the Dictionary via serviceCopy — one source of truth per concern.
module App.Features.Home.Components.Services where

import App.Features.Home.Components.ServiceCard (renderServiceCard)
import App.Html (Html, class_, el, text)
import App.Ui.Container (container)
import Data.Content (services)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)

renderServices :: Lang -> Html
renderServices lang =
  let
    d = (dict lang).services
  in
    el "section" [ class_ "py-20 sm:py-28 bg-white dark:bg-gray-900/50 transition-colors" ]
      [ container "max-w-7xl" ""
          [ container "max-w-2xl" "text-center"
              [ el "p" [ class_ "text-xs font-mono font-semibold uppercase tracking-widest text-emerald-700 dark:text-emerald-400" ] [ text "Features" ]
              , el "h2" [ class_ "mt-2 font-display text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl" ]
                  [ text d.sectionTitle ]
              ]
          , el "div" [ class_ "mt-12 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3" ]
              [ foldMap (renderServiceCard lang) services ]
          ]
      ]

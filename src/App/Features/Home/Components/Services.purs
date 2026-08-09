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
    el "section" [ class_ "py-20 bg-white dark:bg-slate-950" ]
      [ container "max-w-7xl" ""
          [ container "max-w-2xl" "text-center"
              [ el "h2" [ class_ "font-display text-3xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-4xl" ]
                  [ text d.sectionTitle ]
              ]
          , el "div" [ class_ "mx-auto mt-16 grid max-w-2xl grid-cols-1 gap-x-8 gap-y-16 sm:mt-20 lg:mx-0 lg:max-w-none lg:grid-cols-3" ]
              [ foldMap (renderServiceCard lang) services ]
          ]
      ]

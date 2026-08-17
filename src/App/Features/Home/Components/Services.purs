-- | Services section — grid of service cards
-- |
-- | Card metadata (price, image) comes from Data.Content; localized copy comes
-- | from the Dictionary via serviceCopy — one source of truth per concern.
module App.Features.Home.Components.Services where

import App.Features.Home.Components.ServiceCard (renderServiceCard)
import App.Html (Html, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Container (container)
import Data.Content (services)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)

renderServices :: Lang -> Html
renderServices lang =
  let
    d = (dict lang).services
  in
    el "section" [ class_ "py-16 sm:py-24 bg-white dark:bg-zinc-950 border-b border-zinc-200 dark:border-zinc-800" ]
      [ container "max-w-7xl" ""
          [ el "div" [ class_ "max-w-2xl mb-12" ]
              [ el "div" [ class_ "mb-3" ]
                  [ Badge.badge Badge.Neutral "CAPABILITIES & MODULES" ]
              , el "h2" [ class_ "font-display text-3xl sm:text-4xl font-extrabold tracking-tight text-zinc-950 dark:text-white" ]
                  [ text d.sectionTitle ]
              ]
          , el "div" [ class_ "grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3" ]
              [ foldMap (renderServiceCard lang) services ]
          ]
      ]

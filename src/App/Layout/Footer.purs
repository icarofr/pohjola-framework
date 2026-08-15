-- | Footer — brand, navigation, structured project links, copyright
module App.Layout.Footer where

import App.Alpine (navLink)
import App.Html (Html, attr, class_, el, href, rel_, target_, text)
import App.Ui.Social (renderSocial)
import Data.Content (bookingUrl, siteInfo)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)
import Data.Route (Route, navItems)

render :: Lang -> Route -> Html
render lang currentRoute =
  let
    d = (dict lang).footer
  in
    el "footer" [ class_ "bg-white dark:bg-gray-950 text-gray-600 dark:text-gray-400 border-t border-gray-200 dark:border-white/10 transition-colors" ]
      [ el "div" [ class_ "mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8 lg:py-16" ]
          [ el "div" [ class_ "grid grid-cols-1 gap-10 sm:grid-cols-2 lg:grid-cols-4" ]
              [ -- Brand
                el "div" [ class_ "lg:col-span-2 space-y-4" ]
                  [ el "div" [ class_ "flex items-center gap-x-2.5" ]
                      [ el "div" [ class_ "size-7 rounded-lg bg-emerald-600 flex items-center justify-center text-white font-bold text-xs shadow-xs" ]
                          [ el "svg"
                              [ class_ "size-4"
                              , attr "viewBox" "0 0 24 24"
                              , attr "fill" "none"
                              , attr "stroke" "currentColor"
                              , attr "stroke-width" "2"
                              ]
                              [ el "path"
                                  [ attr "stroke-linecap" "round"
                                  , attr "stroke-linejoin" "round"
                                  , attr "d" "M13 10V3L4 14h7v7l9-11h-7z"
                                  ]
                                  []
                              ]
                          ]
                      , el "h3" [ class_ "font-display text-lg font-bold text-gray-900 dark:text-white tracking-tight" ] [ text siteInfo.title ]
                      ]
                  , el "p" [ class_ "text-sm/6 text-gray-600 dark:text-gray-400 max-w-sm font-normal" ] [ text siteInfo.description ]
                  , el "div" [ class_ "pt-2 flex space-x-3" ]
                      [ renderSocial bookingUrl "github"
                      ]
                  ]
              -- Navigation
              , el "div" []
                  [ el "h4" [ class_ "text-xs font-semibold uppercase tracking-wider text-gray-900 dark:text-white" ] [ text d.explore ]
                  , el "ul" [ class_ "mt-4 space-y-3" ]
                      [ foldMap (renderFooterNav lang currentRoute) (navItems lang) ]
                  ]
              -- Resources & Ecosystem
              , el "div" []
                  [ el "h4" [ class_ "text-xs font-semibold uppercase tracking-wider text-gray-900 dark:text-white" ] [ text d.resources ]
                  , el "ul" [ class_ "mt-4 space-y-3 text-sm" ]
                      [ el "li" []
                          [ el "a"
                              [ href "https://github.com/icarofr/pohjola-framework"
                              , target_ "_blank"
                              , rel_ "noopener noreferrer"
                              , class_ "text-gray-600 hover:text-emerald-600 dark:text-gray-400 dark:hover:text-white transition-colors"
                              ]
                              [ text d.github ]
                          ]
                      , el "li" []
                          [ el "a"
                              [ href "https://github.com/icarofr/pohjola-framework/issues"
                              , target_ "_blank"
                              , rel_ "noopener noreferrer"
                              , class_ "text-gray-600 hover:text-emerald-600 dark:text-gray-400 dark:hover:text-white transition-colors"
                              ]
                              [ text d.issues ]
                          ]
                      , el "li" []
                          [ el "a"
                              [ href "https://www.purescript.org"
                              , target_ "_blank"
                              , rel_ "noopener noreferrer"
                              , class_ "text-gray-600 hover:text-emerald-600 dark:text-gray-400 dark:hover:text-white transition-colors"
                              ]
                              [ text "PureScript" ]
                          ]
                      , el "li" []
                          [ el "a"
                              [ href "https://bun.sh"
                              , target_ "_blank"
                              , rel_ "noopener noreferrer"
                              , class_ "text-gray-600 hover:text-emerald-600 dark:text-gray-400 dark:hover:text-white transition-colors"
                              ]
                              [ text "Bun Runtime" ]
                          ]
                      ]
                  ]
              ]
          , el "div" [ class_ "mt-12 pt-8 border-t border-gray-200 dark:border-white/10 text-xs text-gray-500 dark:text-gray-400 font-normal" ]
              [ el "p" [] [ text d.copyright ] ]
          ]
      ]

renderFooterNav :: Lang -> Route -> { label :: String, route :: Route } -> Html
renderFooterNav lang currentRoute item =
  el "li" []
    [ navLink { lang, target: item.route, current: currentRoute }
        [ class_ "text-sm text-gray-600 hover:text-emerald-600 dark:text-gray-400 dark:hover:text-white transition-colors" ]
        [ text item.label ]
    ]

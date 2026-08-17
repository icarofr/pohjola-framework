-- | Footer — brand, navigation, structured project links, copyright
module App.Layout.Footer where

import App.Alpine (navLink)
import App.Html (Html, attr, class_, el, href, rel_, target_, text)
import App.Ui.Badge as Badge
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
    el "footer" [ class_ "bg-white dark:bg-zinc-950 text-zinc-600 dark:text-zinc-400 border-t border-zinc-200 dark:border-zinc-800 transition-colors" ]
      [ el "div" [ class_ "mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8 lg:py-16" ]
          [ el "div" [ class_ "grid grid-cols-1 gap-10 sm:grid-cols-2 lg:grid-cols-4" ]
              [ -- Brand
                el "div" [ class_ "lg:col-span-2 space-y-4" ]
                  [ el "div" [ class_ "flex items-center gap-x-3" ]
                      [ el "div" [ class_ "size-7 rounded-md bg-zinc-900 dark:bg-zinc-100 flex items-center justify-center text-emerald-400 dark:text-emerald-700 font-bold text-xs" ]
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
                      , el "h3" [ class_ "font-mono text-sm font-bold text-zinc-900 dark:text-white uppercase tracking-widest" ] [ text siteInfo.title ]
                      , Badge.badge Badge.BadgeSuccess "OPERATIONAL"
                      ]
                  , el "p" [ class_ "text-sm leading-relaxed text-zinc-600 dark:text-zinc-400 max-w-sm font-normal" ] [ text siteInfo.description ]
                  , el "div" [ class_ "pt-2 flex space-x-3" ]
                      [ renderSocial bookingUrl "github"
                      ]
                  ]
              -- Navigation
              , el "div" []
                  [ el "h4" [ class_ "text-xs font-mono font-semibold uppercase tracking-wider text-zinc-900 dark:text-white" ] [ text d.explore ]
                  , el "ul" [ class_ "mt-4 space-y-2.5 text-sm" ]
                      [ foldMap (renderFooterNav lang currentRoute) (navItems lang) ]
                  ]
              -- Resources & Ecosystem
              , el "div" []
                  [ el "h4" [ class_ "text-xs font-mono font-semibold uppercase tracking-wider text-zinc-900 dark:text-white" ] [ text d.resources ]
                  , el "ul" [ class_ "mt-4 space-y-2.5 text-sm font-mono text-xs" ]
                      [ el "li" []
                          [ el "a"
                              [ href "https://github.com/icarofr/pohjola-framework"
                              , target_ "_blank"
                              , rel_ "noopener noreferrer"
                              , class_ "text-zinc-600 hover:text-emerald-700 dark:text-zinc-400 dark:hover:text-white transition-colors"
                              ]
                              [ text d.github ]
                          ]
                      , el "li" []
                          [ el "a"
                              [ href "https://github.com/icarofr/pohjola-framework/issues"
                              , target_ "_blank"
                              , rel_ "noopener noreferrer"
                              , class_ "text-zinc-600 hover:text-emerald-700 dark:text-zinc-400 dark:hover:text-white transition-colors"
                              ]
                              [ text d.issues ]
                          ]
                      , el "li" []
                          [ el "a"
                              [ href "https://www.purescript.org"
                              , target_ "_blank"
                              , rel_ "noopener noreferrer"
                              , class_ "text-zinc-600 hover:text-emerald-700 dark:text-zinc-400 dark:hover:text-white transition-colors"
                              ]
                              [ text "PureScript 0.15.16" ]
                          ]
                      , el "li" []
                          [ el "a"
                              [ href "https://bun.sh"
                              , target_ "_blank"
                              , rel_ "noopener noreferrer"
                              , class_ "text-zinc-600 hover:text-emerald-700 dark:text-zinc-400 dark:hover:text-white transition-colors"
                              ]
                              [ text "Bun.serve Runtime" ]
                          ]
                      ]
                  ]
              ]
          , el "div" [ class_ "mt-12 pt-8 border-t border-zinc-200 dark:border-zinc-800 text-xs font-mono text-zinc-500 dark:text-zinc-400 flex flex-col sm:flex-row justify-between gap-4" ]
              [ el "p" [] [ text d.copyright ]
              , el "p" [ class_ "text-zinc-400 dark:text-zinc-600" ] [ text "ARCHITECTURAL TOTALITY • 0kB CLIENT RUNTIME" ]
              ]
          ]
      ]

renderFooterNav :: Lang -> Route -> { label :: String, route :: Route } -> Html
renderFooterNav lang currentRoute item =
  el "li" []
    [ navLink { lang, current: currentRoute, target: item.route }
        [ class_ "text-zinc-600 hover:text-emerald-700 dark:text-zinc-400 dark:hover:text-white transition-colors text-sm font-medium" ]
        [ text item.label ]
    ]

-- | Site footer — DaisyUI semantic footer component
module App.Layout.Footer where

import Prelude

import App.Alpine (navLink)
import App.Html (Html, attr, class_, el, href, rel_, target_, text)
import App.Layout.Icons (githubIcon, pohjolaLogo)
import App.Ui.Badge as Badge
import Data.Content (siteInfo)
import Data.I18n (Dictionary, Lang, dict)
import Data.Route (Route(..))

render :: Lang -> Route -> Html
render lang currentRoute =
  let
    d = dict lang
  in
    el "footer"
      [ class_ "bg-base-200 text-base-content border-t border-base-300 transition-colors" ]
      [ el "div" [ class_ "max-w-5xl mx-auto px-4 py-12 sm:px-6 lg:px-8 space-y-8" ]
          [ el "div" [ class_ "grid grid-cols-1 gap-10 sm:grid-cols-2 lg:grid-cols-4" ]
              [ -- Brand Block
                el "div" [ class_ "lg:col-span-2 space-y-4" ]
                  [ el "div" [ class_ "flex items-center gap-x-3" ]
                      [ el "div" [ class_ "size-7 rounded-md bg-primary flex items-center justify-center text-primary-content font-bold text-xs" ]
                          [ pohjolaLogo ]
                      , el "h3" [ class_ "font-mono text-sm font-bold tracking-tight text-base-content" ] [ text siteInfo.title ]
                      ]
                  , el "p" [ class_ "text-sm leading-relaxed text-base-content/80 max-w-sm font-normal" ] [ text siteInfo.description ]
                  , el "div" [ class_ "pt-2 flex space-x-3" ]
                      [ el "a"
                          [ href "https://github.com/icarofr/pohjola-framework"
                          , target_ "_blank"
                          , rel_ "noopener noreferrer"
                          , class_ "btn btn-sm btn-ghost btn-square"
                          , attr "aria-label" "github"
                          ]
                          [ githubIcon ]
                      ]
                  ]

              -- Navigation Links
              , el "div" []
                  [ el "h4" [ class_ "footer-title font-mono text-xs font-semibold uppercase tracking-wider text-base-content" ] [ text "Navigation" ]
                  , el "ul" [ class_ "mt-4 space-y-2.5 text-sm" ]
                      [ el "li" [] [ navLink { lang, current: currentRoute, target: About } [ class_ "link link-hover text-sm" ] [ text d.nav.about ] ]
                      , el "li" [] [ navLink { lang, current: currentRoute, target: Contact } [ class_ "link link-hover text-sm" ] [ text d.nav.contact ] ]
                      , el "li" [] [ navLink { lang, current: currentRoute, target: PostList } [ class_ "link link-hover text-sm" ] [ text d.nav.posts ] ]
                      ]
                  ]

              -- Resources Links
              , el "div" []
                  [ el "h4" [ class_ "footer-title font-mono text-xs font-semibold uppercase tracking-wider text-base-content" ] [ text "Resources" ]
                  , el "ul" [ class_ "mt-4 space-y-2.5 text-sm font-mono text-xs" ]
                      [ el "li" [] [ el "a" [ href "https://github.com/icarofr/pohjola-framework", target_ "_blank", rel_ "noopener noreferrer", class_ "link link-hover" ] [ text "Source Code" ] ]
                      , el "li" [] [ el "a" [ href "https://github.com/icarofr/pohjola-framework/issues", target_ "_blank", rel_ "noopener noreferrer", class_ "link link-hover" ] [ text "Bug Tracker" ] ]
                      , el "li" [] [ el "a" [ href "https://www.purescript.org", target_ "_blank", rel_ "noopener noreferrer", class_ "link link-hover" ] [ text "PureScript 0.15.16" ] ]
                      , el "li" [] [ el "a" [ href "https://bun.sh", target_ "_blank", rel_ "noopener noreferrer", class_ "link link-hover" ] [ text "Bun.serve Runtime" ] ]
                      ]
                  ]
              ]

          -- Bottom strip
          , el "div" [ class_ "pt-8 border-t border-base-300 text-xs font-mono text-base-content/60 flex flex-col sm:flex-row justify-between gap-4" ]
              [ el "p" [] [ text "© 2026 Pohjola Framework. Open source software." ]
              , el "p" [] [ text "PureScript & Bun • MIT License" ]
              ]
          ]
      ]

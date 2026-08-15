-- | Footer — brand, navigation, newsletter form, copyright
-- |
-- | Footer nav links use `navLink` — SPA-feel navigation, minus the hover
-- | prefetch when a link points at the route already shown.
-- | Newsletter form includes a hidden `lang` field so the POST handler
-- | can redirect back to the correct language.
module App.Layout.Footer where

import App.Alpine (navLink)
import App.Form (apiNewsletterPath)
import App.Html (Html, action_, ariaLabel, attr, class_, el, flag, for_, id_, method_, name_, placeholder_, text, type_)
import App.Ui.Social (renderSocial)
import Data.Content (bookingUrl, siteInfo)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict, langTag)
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
              -- Explore
              , el "div" []
                  [ el "h4" [ class_ "text-xs font-semibold uppercase tracking-wider text-gray-900 dark:text-white" ] [ text d.explore ]
                  , el "ul" [ class_ "mt-4 space-y-3" ]
                      [ foldMap (renderFooterNav lang currentRoute) (navItems lang) ]
                  ]
              -- Newsletter
              , el "div" []
                  [ el "h4" [ class_ "text-xs font-semibold uppercase tracking-wider text-gray-900 dark:text-white" ] [ text d.newsletter ]
                  , el "p" [ class_ "mt-3 text-sm/6 text-gray-600 dark:text-gray-400 font-normal" ] [ text d.newsletterText ]
                  , el "form"
                      [ action_ apiNewsletterPath
                      , method_ "POST"
                      , class_ "mt-4 flex flex-col sm:flex-row gap-2"
                      ]
                      [ el "input"
                          [ type_ "hidden"
                          , name_ "lang"
                          , attr "value" (langTag lang)
                          ]
                          []
                      -- Honeypot field
                      , el "div" [ class_ "absolute -left-[9999px]", attr "aria-hidden" "true" ]
                          [ el "label" [ for_ "newsletter-website", class_ "block text-sm font-medium text-gray-700 dark:text-gray-300" ]
                              [ text "Website" ]
                          , el "input"
                              [ type_ "text"
                              , id_ "newsletter-website"
                              , name_ "website"
                              , attr "tabindex" "-1"
                              , attr "autocomplete" "off"
                              ]
                              []
                          ]
                      , el "input"
                          [ type_ "email"
                          , name_ "email"
                          , flag "required"
                          , placeholder_ d.newsletterPlaceholder
                          , ariaLabel (dict lang).common.newsletterEmailLabel
                          , class_ "min-w-0 flex-auto rounded-md bg-white dark:bg-white/5 px-3.5 py-2 text-base text-gray-900 dark:text-white outline-1 -outline-offset-1 outline-gray-300 dark:outline-white/10 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-emerald-600 sm:text-sm/6"
                          ]
                          []
                      , el "button"
                          [ type_ "submit"
                          , class_ "flex-none rounded-md bg-emerald-600 px-3.5 py-2 text-sm font-semibold text-white shadow-xs hover:bg-emerald-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600 transition-colors cursor-pointer select-none"
                          ]
                          [ text d.newsletterButton ]
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

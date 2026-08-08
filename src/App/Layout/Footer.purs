-- | Footer — brand, navigation, newsletter form, copyright
-- |
-- | Footer nav links use `spaLink` for SPA-feel navigation.
-- | Newsletter form includes a hidden `lang` field so the POST handler
-- | can redirect back to the correct language.
module App.Layout.Footer where

import App.Alpine (spaLink)
import App.Form (apiNewsletterPath)
import App.Html (Html, action_, ariaLabel, attr, class_, el, flag, for_, id_, method_, name_, placeholder_, text, type_)
import App.Ui.Social (renderSocial)
import Data.Content (siteInfo)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict, langTag)
import Data.Route (Route, navItems)

render :: Lang -> Html
render lang =
  let
    d = (dict lang).footer
  in
    el "footer" [ class_ "bg-slate-900 text-slate-300" ]
      [ el "div" [ class_ "mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8" ]
          [ el "div" [ class_ "grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-4" ]
              [ -- Brand
                el "div" [ class_ "lg:col-span-2" ]
                  [ el "h3" [ class_ "font-display text-lg font-bold text-white" ] [ text siteInfo.title ]
                  , el "p" [ class_ "mt-2 text-sm text-slate-400 max-w-sm" ] [ text siteInfo.description ]
                  , el "div" [ class_ "mt-4 flex space-x-3" ]
                      [ renderSocial siteInfo.facebookUrl "facebook"
                      , renderSocial siteInfo.instagramUrl "instagram"
                      ]
                  ]
              -- Explore
              , el "div" []
                  [ el "h4" [ class_ "text-sm font-semibold uppercase tracking-wider text-slate-400" ] [ text d.explore ]
                  , el "ul" [ class_ "mt-4 space-y-2" ]
                      [ foldMap (renderFooterNav lang) (navItems lang) ]
                  ]
              -- Newsletter
              , el "div" []
                  [ el "h4" [ class_ "text-sm font-semibold uppercase tracking-wider text-slate-400" ] [ text d.newsletter ]
                  , el "p" [ class_ "mt-3 text-sm text-slate-400" ] [ text d.newsletterText ]
                  , el "form"
                      [ action_ apiNewsletterPath
                      , method_ "POST"
                      , class_ "mt-3 flex gap-2"
                      ]
                      [ el "input"
                          [ type_ "hidden"
                          , name_ "lang"
                          , attr "value" (langTag lang)
                          ]
                          []
                      -- Honeypot field
                      , el "div" [ class_ "absolute -left-[9999px]", attr "aria-hidden" "true" ]
                          [ el "label" [ for_ "newsletter-website", class_ "block text-sm font-medium text-slate-700 dark:text-slate-300" ]
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
                          , class_ "flex-1 rounded-md border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-white placeholder-slate-500 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                          ]
                          []
                      , el "button"
                          [ type_ "submit"
                          , class_ "rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-500 transition-colors"
                          ]
                          [ text d.newsletterButton ]
                      ]
                  ]
              ]
          -- Copyright
          , el "div" [ class_ "mt-10 border-t border-slate-800 pt-6 flex flex-col sm:flex-row justify-between items-center gap-2" ]
              [ el "p" [ class_ "text-xs text-slate-400" ] [ text d.copyright ]
              ]
          ]
      ]

renderFooterNav :: Lang -> { label :: String, route :: Route } -> Html
renderFooterNav lang item =
  el "li" []
    [ spaLink lang item.route
        [ class_ "text-sm text-slate-400 hover:text-white transition-colors" ]
        [ text item.label ]
    ]


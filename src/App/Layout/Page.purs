-- | HTTP document wrapper — not the template entry. Feature views call
-- | `App.Ui.Templates.Render.renderPage`.
module App.Layout.Page where

import Prelude

import App.Error (AppError)
import App.Form (FormStatus(..), formStatusQuery, statusText)
import App.Html (Html, attr, class_, doctype, el, flag, href, name_, render, src, text)
import App.Layout.Head (renderHead)
import App.Layout.Scripts (HeadScript(..), renderHeadScript)
import App.Layout.Styles (stylesCss)
import App.Ui.Alert (AlertVariant(..), alert)
import App.Ui.Templates.SiteShell as Shell
import Data.Either (Either(..))
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict, langTag)
import Data.Maybe (Maybe, maybe)
import Data.Route (Route, prefetchFor, routeUrl)
import Effect.Aff (Aff)

bodyClass :: String
bodyClass = "bg-base-100 text-base-content"

staticPage :: Html -> Aff (Either AppError Html)
staticPage = pure <<< Right

maybeStatusBanner :: Lang -> Maybe FormStatus -> Html
maybeStatusBanner lang = maybe (text "") \status ->
  let
    variant = case status of
      FormSuccess -> AlertSuccess
      FormError -> AlertError
      FormSubscribed -> AlertSuccess
  in
    el "div" [ attr "data-form-status" (formStatusQuery status) ]
      [ alert variant (statusText lang status) ]

renderDocument :: String -> String -> Lang -> Route -> Maybe FormStatus -> Html -> String
renderDocument baseUrl nonce lang route maybeStatus content =
  render $
    doctype
      <> el "html" [ attr "lang" (langTag lang) ]
        [ el "head" []
            [ renderHead baseUrl nonce lang route
            , renderPrefetch lang (prefetchFor route)
            ]
        , el "body" [ class_ bodyClass ]
            [ maybeStatusBanner lang maybeStatus
            , content
            , renderScripts nonce
            ]
        ]

renderScripts :: String -> Html
renderScripts nonce =
  el "script" [ flag "defer", src "/assets/js/alpine-ajax.min.js", attr "nonce" nonce ] []
    <> el "script" [ flag "defer", src "/assets/js/alpinejs.min.js", attr "nonce" nonce ] []

renderFragment :: Lang -> Route -> Html -> String
renderFragment _ _ content =
  render content

renderErrorFragment :: Lang -> Route -> Int -> String
renderErrorFragment lang _ status =
  render (Shell.siteErrorPage lang status)

renderErrorPage :: String -> Lang -> Int -> String
renderErrorPage nonce lang status =
  let
    d = dict lang
  in
    render $
      doctype
        <> el "html" [ attr "lang" (langTag lang) ]
          [ el "head" []
              [ el "meta" [ attr "charset" "UTF-8" ] []
              , el "meta" [ attr "name" "viewport", attr "content" "width=device-width, initial-scale=1.0" ] []
              , el "meta" [ name_ "robots", attr "content" "noindex" ] []
              , el "title" [] [ text (show status <> " — " <> d.common.siteTitle) ]
              , el "style" [] [ text (stylesCss <> "\n[x-cloak]{display:none!important}") ]
              , renderHeadScript nonce DarkModeInit
              ]
          , el "body" [ class_ bodyClass ]
              [ Shell.siteErrorPage lang status
              , renderScripts nonce
              ]
          ]

renderPrefetch :: Lang -> Array Route -> Html
renderPrefetch lang routes =
  foldMap (\route -> el "link" [ attr "rel" "prefetch", href (routeUrl lang route) ] []) routes

renderShellOpen :: String -> String -> Lang -> Route -> String
renderShellOpen baseUrl nonce lang route =
  "<!DOCTYPE html>"
    <> "<html lang=\""
    <> langTag lang
    <> "\">"
    <> render (el "head" [] [ renderHead baseUrl nonce lang route ])
    <> "<body class=\""
    <> bodyClass
    <> "\">"

renderShellClose :: String -> Lang -> Route -> String
renderShellClose nonce _ _ =
  render (renderScripts nonce) <> "</body></html>"

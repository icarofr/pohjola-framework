-- | Full page shell — feature views supply complete page templates.
module App.Layout.Page where

import Prelude

import App.Error (AppError)
import App.Form (FormStatus(..), formStatusQuery, statusText)
import App.Html (Html, attr, class_, doctype, el, flag, href, id_, name_, render, src, text)
import App.Layout.Head (renderHead)
import App.Layout.Scripts (HeadScript(..), renderHeadScript)
import App.Layout.Styles (stylesCss)
import App.Ui.Alert (AlertVariant(..), alert)
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

renderPage :: String -> String -> Lang -> Route -> Maybe FormStatus -> Html -> String
renderPage baseUrl nonce lang route maybeStatus content =
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

errorContent :: Lang -> Int -> Html
errorContent lang status =
  let
    d = dict lang
    message = case status of
      404 -> d.common.error404
      _ -> d.common.error500
  in
    el "div" [ class_ "bg-base-100 text-base-content", id_ "content" ]
      [ el "div" [ class_ "mx-auto max-w-7xl px-6 py-32 text-center lg:px-8" ]
          [ el "h1" [ class_ "text-5xl font-semibold tracking-tight text-base-content" ]
              [ text (show status) ]
          , el "p" [ class_ "mt-6 text-lg text-base-content opacity-70" ] [ text message ]
          ]
      ]

renderErrorFragment :: Lang -> Route -> Int -> String
renderErrorFragment lang _ status =
  render (errorContent lang status)

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
              [ errorContent lang status
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

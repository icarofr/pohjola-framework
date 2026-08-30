-- | Full page shell — DaisyUI drawer wraps navbar + main + footer.
module App.Layout.Page where

import Prelude

import App.Alpine (contentTarget, navLink)
import App.Error (AppError)
import App.Form (FormStatus(..), formStatusQuery, statusText)
import App.Html (Html, attr, class_, doctype, el, escape, flag, href, id_, name_, render, src, text, type_)
import App.Layout.Footer (render) as Footer
import App.Layout.Head (renderHead)
import App.Layout.Header (render) as Header
import App.Layout.Scripts (HeadScript(..), renderHeadScript)
import App.Layout.Styles (stylesCss)
import App.Ui.Alert (AlertVariant(..), alert)
import Data.Either (Either(..))
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict, langTag)
import Data.Maybe (Maybe(..), maybe)
import Data.Route (Route(..), prefetchFor, routeTitle, routeUrl)
import Effect.Aff (Aff)

bodyClass :: String
bodyClass = "min-h-screen"

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

shell :: Lang -> Route -> Html -> Array Html
shell lang route inner =
  let
    d = dict lang
  in
    [ el "input" [ id_ "nav-drawer", type_ "checkbox", class_ "drawer-toggle" ] []
    , el "div" [ class_ "drawer-content" ]
        [ Header.render lang route
        , inner
        , Footer.render lang route
        ]
    , el "div" [ class_ "drawer-side" ]
        [ el "label" [ attr "for" "nav-drawer", class_ "drawer-overlay", attr "aria-label" d.common.menuLabel ] []
        , el "ul" [ class_ "menu bg-base-200 min-h-full w-80" ]
            [ el "li" [] [ navLink { lang, current: route, target: About } [] [ text d.nav.about ] ]
            , el "li" [] [ navLink { lang, current: route, target: Contact } [] [ text d.nav.contact ] ]
            , el "li" [] [ navLink { lang, current: route, target: PostList } [] [ text d.nav.posts ] ]
            ]
        ]
    ]

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
            [ el "div" [ class_ "drawer" ]
                ( shell lang route
                    ( el "main"
                        [ id_ contentTarget, attr "data-page-title" (routeTitle lang route) ]
                        [ maybeStatusBanner lang maybeStatus, content ]
                    )
                )
            , renderScripts nonce
            ]
        ]

renderScripts :: String -> Html
renderScripts nonce =
  el "script" [ flag "defer", src "/assets/js/alpine-ajax.min.js", attr "nonce" nonce ] []
    <> el "script" [ flag "defer", src "/assets/js/alpinejs.min.js", attr "nonce" nonce ] []

renderFragment :: Lang -> Route -> Html -> String
renderFragment lang route content =
  render $
    el "div" [ class_ "drawer" ]
      ( shell lang route
          ( el "main"
              [ id_ contentTarget, attr "data-page-title" (routeTitle lang route) ]
              [ maybeStatusBanner lang Nothing, content ]
          )
      )

errorContent :: Lang -> Int -> Html
errorContent lang status =
  let
    d = dict lang
    message = case status of
      404 -> d.common.error404
      _ -> d.common.error500
  in
    el "div" [ class_ "hero" ]
      [ el "div" [ class_ "hero-content text-center" ]
          [ el "div" []
              [ el "h1" [ class_ "text-5xl font-bold" ] [ text (show status) ]
              , el "p" [ class_ "py-6" ] [ text message ]
              ]
          ]
      ]

renderErrorFragment :: Lang -> Route -> Int -> String
renderErrorFragment lang route status =
  renderFragment lang route (errorContent lang status)

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
              [ el "div" [ class_ "drawer" ]
                  ( shell lang Home
                      (el "main" [ id_ contentTarget ] [ errorContent lang status ])
                  )
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
    <> "<div class=\"drawer\">"
    <> render (el "input" [ id_ "nav-drawer", type_ "checkbox", class_ "drawer-toggle" ] [])
    <> "<div class=\"drawer-content\">"
    <> render (Header.render lang route)
    <> "<main id=\""
    <> contentTarget
    <> "\" data-page-title=\""
    <> escape (routeTitle lang route)
    <> "\">"

renderShellClose :: String -> Lang -> Route -> String
renderShellClose nonce lang route =
  "</main>"
    <> render (Footer.render lang route)
    <> "</div>"
    <> render
      ( el "div" [ class_ "drawer-side" ]
          [ el "label" [ attr "for" "nav-drawer", class_ "drawer-overlay" ] []
          , el "ul" [ class_ "menu bg-base-200 min-h-full w-80" ]
              [ el "li" [] [ navLink { lang, current: route, target: About } [] [ text (dict lang).nav.about ] ]
              , el "li" [] [ navLink { lang, current: route, target: Contact } [] [ text (dict lang).nav.contact ] ]
              , el "li" [] [ navLink { lang, current: route, target: PostList } [] [ text (dict lang).nav.posts ] ]
              ]
          ]
      )
    <> "</div>"
    <> render (renderScripts nonce)
    <> "</body></html>"

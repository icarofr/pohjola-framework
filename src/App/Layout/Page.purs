-- | HTTP document wrapper — not the template entry. Feature views call
-- | `App.Ui.Templates.Render.renderPage`.
module App.Layout.Page where

import Prelude

import App.DatastarShell as DatastarShell
import App.Error (AppError)
import App.Html (Html, attr, class_, doctype, el, href, name_, render, src, text, type_)
import App.Layout.Head (renderHead)
import App.Layout.Scripts (HeadScript(..), renderHeadScript)
import App.Layout.Styles (stylesCss)
import Data.Either (Either(..))
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict, langTag)
import Data.Route (Route, prefetchFor, routeUrl)
import Effect.Aff (Aff)

bodyClass :: String
bodyClass = "bg-base-100 text-base-content"

staticPage :: Html -> Aff (Either AppError Html)
staticPage = pure <<< Right

renderDocument :: String -> String -> Lang -> Route -> Html -> String
renderDocument baseUrl nonce lang route content =
  render $
    doctype
      <> el "html" [ attr "lang" (langTag lang) ]
        [ el "head" []
            [ renderHead baseUrl nonce lang route
            , renderPrefetch lang (prefetchFor route)
            ]
        , el "body" [ class_ bodyClass ]
            [ content
            , renderScripts nonce
            ]
        ]

-- | The one script tag (Datastar's ESM bundle) plus the hand-rolled
-- | pushState/popstate shell-router glue Datastar itself doesn't provide.
renderScripts :: String -> Html
renderScripts nonce =
  el "script" [ type_ "module", src "/assets/js/datastar.js", attr "nonce" nonce ] []
    <> renderHeadScript nonce DsShellRouter

-- | The SSE-patch payload for a Datastar-request error (App.Main wraps this
-- | in datastar-patch-elements framing) — never a full document, so a
-- | fragment error never nests a complete <!DOCTYPE> inside #content.
renderErrorFragment :: Lang -> Int -> String
renderErrorFragment lang status =
  render (DatastarShell.dsSiteErrorPage lang status)

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
              , el "title" [] [ text (show status <> " - " <> d.common.siteTitle) ]
              , el "style" [] [ text stylesCss ]
              , renderHeadScript nonce DarkModeInit
              ]
          , el "body" [ class_ bodyClass ]
              [ DatastarShell.dsSiteErrorPage lang status
              , renderScripts nonce
              ]
          ]

renderPrefetch :: Lang -> Array Route -> Html
renderPrefetch lang routes =
  foldMap (\route -> el "link" [ attr "rel" "prefetch", href (routeUrl lang route) ] []) routes

-- | Dormant streaming choreography (App.Server.streamResponse /
-- | App.ServerBun.streamResponseImpl, both zero call sites) — "shell now,
-- | fetch content later". Unrelated to the Alpine/Datastar transport swap;
-- | kept working (renderHead/renderScripts are both transport-agnostic)
-- | rather than removed as part of this migration's actual scope.
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

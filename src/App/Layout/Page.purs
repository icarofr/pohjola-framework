-- | HTTP document wrapper — not the template entry. Feature views call
-- | `App.Ui.Templates.Render.renderPage`.
module App.Layout.Page where

import Prelude

import App.DatastarShell as DatastarShell
import App.Error (AppError)
import App.Html (Html, attr, class_, doctype, el, empty, name_, render, src, text, type_)
import App.Layout.Head (DocumentChrome, productionChrome, renderHead)
import App.Layout.Scripts (HeadScript(..), renderHeadScript)
import App.Layout.Styles (stylesCss)
import Data.Either (Either(..))
import Data.I18n (Lang, dict, langTag)
import Data.Route (Route)
import Effect.Aff (Aff)

bodyClass :: String
bodyClass = "bg-base-100 text-base-content"

staticPage :: Html -> Aff (Either AppError Html)
staticPage = pure <<< Right

renderDocument :: String -> String -> Lang -> Route -> Html -> String
renderDocument = renderDocumentWith productionChrome

renderDocumentWith :: DocumentChrome -> String -> String -> Lang -> Route -> Html -> String
renderDocumentWith chrome = renderDocumentExtraHeadWith chrome mempty

-- | Same shell as `renderDocument`, plus arbitrary extra `<head>` content
-- | composed through the `Html` DSL rather than post-processing the
-- | rendered string. Exists for `App.Cli.ExportStatic`'s CSP `<meta>` tag
-- | (the live server sends CSP as a header instead, via `withCsp`, so
-- | `renderDocument` itself needs no such hook) — a static export has no
-- | server to send a header from, so the policy has to live in the markup.
-- |
-- | `extraHead` comes FIRST, before `renderHead`'s own content: a CSP
-- | `<meta>` tag only governs elements parsed after it, not retroactively —
-- | placed second, it would leave `renderHead`'s inline scripts
-- | (DarkModeInit, and DevLiveReload when that chrome is on) executing
-- | before any policy applied to them at all, silently ungated rather
-- | than merely blocked.
renderDocumentExtraHead :: Html -> String -> String -> Lang -> Route -> Html -> String
renderDocumentExtraHead extraHead = renderDocumentExtraHeadWith productionChrome extraHead

renderDocumentExtraHeadWith :: DocumentChrome -> Html -> String -> String -> Lang -> Route -> Html -> String
renderDocumentExtraHeadWith chrome extraHead baseUrl nonce lang route content =
  renderShell lang nonce (extraHead <> renderHead chrome baseUrl nonce lang route) content

-- | The one place that knows what a Pohjola document IS, structurally:
-- | doctype, `<html lang>`, a head, a body, plus the shared scripts. Every
-- | document-shell function (`renderDocumentExtraHead`, `renderErrorPage`)
-- | differs only in what head/body content it supplies, never in the
-- | skeleton — so there's exactly one seam to fix if that skeleton ever
-- | needs to change, instead of one per caller.
renderShell :: Lang -> String -> Html -> Html -> String
renderShell lang nonce headContent bodyContent =
  render $
    doctype
      <> el "html" [ attr "lang" (langTag lang) ]
        [ el "head" [] [ headContent ]
        , el "body" [ class_ bodyClass ]
            [ bodyContent
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

renderErrorPage :: DocumentChrome -> String -> Lang -> Int -> String
renderErrorPage chrome nonce lang status =
  let
    d = dict lang
    headContent =
      el "meta" [ attr "charset" "UTF-8" ] []
        <> el "meta" [ attr "name" "viewport", attr "content" "width=device-width, initial-scale=1.0" ] []
        <> el "meta" [ name_ "robots", attr "content" "noindex" ] []
        <> el "title" [] [ text (show status <> " - " <> d.common.siteTitle) ]
        <>
          ( if chrome.linkedCss then
              el "link" [ attr "rel" "stylesheet", attr "href" "/css/styles.css" ] []
            else
              el "style" [] [ text stylesCss ]
          )
        <> renderHeadScript nonce DarkModeInit
        <>
          ( if chrome.liveReload then
              renderHeadScript nonce DevLiveReload
            else
              empty
          )
  in
    renderShell lang nonce headContent (DatastarShell.dsSiteErrorPage lang status)


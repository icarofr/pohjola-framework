-- | Full page shell — assembles head + header + main content + footer + scripts
-- |
-- | `renderPage` produces a full HTML document. `renderFragment` produces the
-- | AJAX fragment (nav + content) for Alpine AJAX navigation. Both share the
-- | same `contentTarget` ID from App.Alpine — the contract between the server
-- | and Alpine AJAX.
module App.Layout.Page where

import Prelude

import App.Alpine (contentTarget)
import App.Error (AppError)
import App.Form (FormStatus(..), formStatusQuery, statusText)
import App.Html (Html, attr, class_, doctype, el, escape, flag, href, id_, name_, render, src, text)
import App.Layout.Head (renderHead)
import App.Layout.Header (render) as Header
import App.Layout.Footer (render) as Footer
import App.Layout.Scripts (HeadScript(..), renderHeadScript)
import App.Layout.Styles (stylesCss)
import App.Ui.Alert as Alert
import App.Ui.Alert (AlertVariant(..))
import App.Ui.Container (container)
import App.Ui.TextTone (TextTone(..), toneClass)
import Data.Either (Either(..))
import Data.Foldable (foldMap)
import Data.I18n (Lang, langTag, dict)
import Data.Maybe (Maybe(..), maybe)
import Data.Route (Route(..), prefetchFor, routeTitle, routeUrl)
import Effect.Aff (Aff)

-- | Shared body class — used by renderPage, renderShellOpen, and renderErrorPage.
-- | Extracted to prevent drift between streamed and non-streamed pages.
bodyClass :: String
bodyClass = "bg-base-100 text-base-content min-h-screen flex flex-col font-sans selection:bg-primary selection:text-primary-content"

-- | Pages provide their own render function.
-- | Static pages use `staticPage` to wrap pure Html. Data-backed pages fetch
-- | via Aff and return `Left AppError` on failure. The router handles the error.

-- | Smart constructor for static pages — no Aff, no error path.
-- | Eliminates `pure (Right ...)` noise in static page modules.
staticPage :: Html -> Aff (Either AppError Html)
staticPage = pure <<< Right

-- Helper to generate status banner if applicable
maybeStatusBanner :: Lang -> Maybe FormStatus -> Html
maybeStatusBanner lang = maybe (text "") \status ->
  let
    alertVariant = case status of
      FormSuccess -> AlertSuccess
      FormError -> AlertError
      FormSubscribed -> AlertSuccess
  in
    container "max-w-7xl" "pt-6"
      [ el "div"
          [ attr "data-form-status" (formStatusQuery status) ]
          [ Alert.alert alertVariant (statusText lang status) ]
      ]

-- | Full HTML page — for normal (non-AJAX) requests.
-- | Takes pre-rendered Html (the router has already resolved the Aff).
renderPage :: String -> String -> Lang -> Route -> Maybe FormStatus -> Html -> String
renderPage baseUrl nonce lang route maybeStatus content =
  render $
    doctype
      <> el "html" [ attr "lang" (langTag lang) ]
        [ el "head" []
            [ renderHead baseUrl nonce lang route
            , renderPrefetch lang (prefetchFor route)
            ]
        , el "body"
            [ class_ bodyClass ]
            [ Header.render lang route
            , el "main" [ id_ contentTarget, class_ "flex-1 flex flex-col", attr "data-page-title" (routeTitle lang route) ]
                [ maybeStatusBanner lang maybeStatus
                , content
                ]
            , Footer.render lang route
            , renderScripts nonce
            ]
        ]

-- | Client script tags (Alpine AJAX + Alpine core). Pinned, self-hosted from /assets/js/.
renderScripts :: String -> Html
renderScripts nonce =
  el "script" [ flag "defer", src "/assets/js/alpine-ajax.min.js", attr "nonce" nonce ] []
    <> el "script" [ flag "defer", src "/assets/js/alpinejs.min.js", attr "nonce" nonce ] []

-- | AJAX fragment — nav + content only, for Alpine AJAX requests.
-- | Must contain all x-sync'd elements (nav) and the swap target (#content).
-- | No baseUrl needed: fragments contain no absolute URLs or head metadata.
renderFragment :: Lang -> Route -> Html -> String
renderFragment lang route content =
  render $
    Header.render lang route
      <> el "main" [ id_ contentTarget, class_ "flex-1 flex flex-col", attr "data-page-title" (routeTitle lang route) ]
        [ maybeStatusBanner lang Nothing
        , content
        ]

-- | Rendered error page — branded 404/500 with full layout.
-- | Standalone HTML document (not via renderPage) because error pages have no
-- | real Route — no canonical URL, no hreflang. Includes <meta name="robots"
-- | content="noindex"> since error pages must not be indexed.
-- | The error body itself — shared by the full error document and the error
-- | fragment so the two cannot drift apart.
errorContent :: Lang -> Int -> Html
errorContent lang status =
  let
    d = dict lang
    message = case status of
      404 -> d.common.error404
      _ -> d.common.error500
  in
    container "max-w-3xl" "py-24 sm:py-32 text-center space-y-4"
      [ el "p" [ class_ "text-sm font-mono font-semibold text-primary" ] [ text (show status) ]
      , el "h1" [ class_ "text-4xl sm:text-5xl font-extrabold tracking-tight" ] [ text (show status) ]
      , el "p" [ class_ ("text-lg " <> toneClass Copy) ] [ text message ]
      ]

-- | Error response for an Alpine AJAX fragment request.
-- |
-- | A fragment request must be answered with a fragment. Answering it with
-- | `renderErrorPage` returns a complete `<!DOCTYPE>` document, which the client
-- | then swaps into `#content` — a whole document nested inside the page body.
-- |
-- | This is the mitigation ADR-007 describes for an experimental streaming
-- | path, applied here to the path that actually needs it: AJAX fragments.
renderErrorFragment :: Lang -> Route -> Int -> String
renderErrorFragment lang route status =
  renderFragment lang route (errorContent lang status)

renderErrorPage :: String -> Lang -> Int -> String
renderErrorPage nonce lang status =
  let
    d = dict lang
    content = errorContent lang status
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
          , el "body"
              [ class_ bodyClass ]
              [ Header.render lang Home
              , el "main" [ id_ contentTarget, class_ "flex-1 flex flex-col" ]
                  [ content ]
              , Footer.render lang Home
              , renderScripts nonce
              ]
          ]

-- ============================================================================
-- Prefetch — browser-native <link rel="prefetch"> from prefetchFor
-- ============================================================================

-- | Render <link rel="prefetch"> tags for likely-next routes. Browser-native,
-- | no JS. Prefetches the full page URL (not the fragment) so the browser
-- | cache warms the same URL a hard navigation would request. Alpine AJAX
-- | clicks use the x-alpine-request header (different Vary key), so fragment
-- | prefetches would never cache-hit — full URL prefetch is the honest choice.
renderPrefetch :: Lang -> Array Route -> Html
renderPrefetch lang routes =
  foldMap
    ( \route ->
        el "link" [ attr "rel" "prefetch", href (routeUrl lang route) ] []
    )
    routes

-- ============================================================================
-- Streaming SSR — shell open/close + loading + error fragments
-- ============================================================================

-- | The opening of a full HTML document: doctype, <html>, <head>, <body>,
-- | header, and <main id="content"> — but NOT their closing tags. Streamed
-- | immediately so the browser can parse CSS and show nav while data is in
-- | flight. The content area is empty — it fills when the data resolves.
-- | Uses string concatenation for the shell structure (html/body/main)
-- | because the `el` ADT auto-closes tags. The head and header are rendered
-- | via the ADT (they're complete elements) and embedded as substrings.
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
    <> render (Header.render lang route)
    <> "<main id=\""
    <> contentTarget
    <> "\" class=\"flex-1 flex flex-col\" data-page-title=\""
    <> escape (routeTitle lang route)
    <> "\">"

-- | The closing of a full HTML document: </main>, footer, scripts, </body>,
-- | </html>. Streamed after the content chunk.
renderShellClose :: String -> Lang -> Route -> String
renderShellClose nonce lang route =
  "</main>"
    <> render (Footer.render lang route)
    <> render (renderScripts nonce)
    <> "</body></html>"

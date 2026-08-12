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
import App.Ui.Container (container)
import Data.Either (Either(..))
import Data.Foldable (foldMap)
import Data.I18n (Lang, langTag, dict)
import Data.Maybe (Maybe(..), maybe)
import Data.Route (Route(..), prefetchFor, routeTitle, routeUrl)
import Effect.Aff (Aff)

-- | Shared body class — used by renderPage, renderShellOpen, and renderErrorPage.
-- | Extracted to prevent drift between streamed and non-streamed pages.
bodyClass :: String
bodyClass = "bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 antialiased min-h-screen flex flex-col transition-colors"

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
    statusClass = case status of
      FormSuccess -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      FormError -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      FormSubscribed -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  in
    el "div"
      [ attr "role" "status"
      , attr "data-form-status" (formStatusQuery status)
      , class_ ("p-4 mb-6 rounded-lg " <> statusClass)
      ]
      [ text (statusText lang status) ]

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
            -- Alpine AJAX before Alpine core (plugin must register first)
            -- Pinned versions, self-hosted from /assets/js/ for caching
            , el "script" [ flag "defer", src "/assets/js/alpine-ajax.min.js", attr "nonce" nonce ] []
            , el "script" [ flag "defer", src "/assets/js/alpinejs.min.js", attr "nonce" nonce ] []
            ]
        ]

-- | AJAX fragment — nav + content only, for Alpine AJAX requests.
-- | Must contain all x-sync'd elements (nav) and the swap target (#content).
-- | No baseUrl needed: fragments contain no absolute URLs or head metadata.
renderFragment :: Lang -> Route -> Html -> String
renderFragment lang route content =
  render $ el "div" []
    [ Header.render lang route
    , el "main" [ id_ contentTarget, class_ "flex-1 flex flex-col", attr "data-page-title" (routeTitle lang route) ]
        [ maybeStatusBanner lang Nothing
        , content
        ]
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
    container "max-w-3xl" "py-16 text-center"
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white" ] [ text (show status) ]
      , el "p" [ class_ "mt-4 text-lg text-slate-600 dark:text-slate-300" ] [ text message ]
      ]

-- | Error response for an Alpine AJAX fragment request.
-- |
-- | A fragment request must be answered with a fragment. Answering it with
-- | `renderErrorPage` returns a complete `<!DOCTYPE>` document, which the client
-- | then swaps into `#content` — a whole document nested inside the page body.
-- |
-- | This is the mitigation ADR-007 describes for the streaming path, applied to
-- | the path that actually lacked it. The streaming path already renders a
-- | fragment-shaped error via the feature's own error view
-- | (`renderListContent` → `renderPostsError`); this covers the AJAX path.
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
              , el "link" [ attr "rel" "stylesheet", attr "href" "/css/styles.css" ] []
              , el "style" [] [ text "[x-cloak]{display:none!important}" ]
              , el "script" [ attr "nonce" nonce ] [ text "if(localStorage.getItem('theme')==='dark'||(!localStorage.getItem('theme')&&matchMedia('(prefers-color-scheme:dark)').matches))document.documentElement.classList.add('dark')" ]
              ]
          , el "body"
              [ class_ bodyClass ]
              [ Header.render lang Home
              , el "main" [ id_ contentTarget, class_ "flex-1 flex flex-col" ]
                  [ content ]
              , Footer.render lang Home
              , el "script" [ flag "defer", src "/assets/js/alpine-ajax.min.js", attr "nonce" nonce ] []
              , el "script" [ flag "defer", src "/assets/js/alpinejs.min.js", attr "nonce" nonce ] []
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
    <> render (el "script" [ flag "defer", src "/assets/js/alpine-ajax.min.js", attr "nonce" nonce ] [])
    <> render (el "script" [ flag "defer", src "/assets/js/alpinejs.min.js", attr "nonce" nonce ] [])
    <> "</body></html>"

-- | Escape attribute values for string-concatenated HTML. The `el` ADT
-- | escapes automatically; string-concatenated shells (renderShellOpen)
-- | need manual escaping.


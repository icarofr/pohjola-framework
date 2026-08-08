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
import App.Html (Html, attr, class_, el, escape, flag, href, id_, name_, raw, render, src, text)
import App.Layout.Head (cspNoncePlaceholder, renderHead)
import App.Layout.Header (render) as Header
import App.Layout.Footer (render) as Footer
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
-- | Uses cspNoncePlaceholder in script tags; App.Main replaces it with the
-- | per-request nonce at serve time so the static page cache stays nonce-agnostic.
renderPage :: String -> Lang -> Route -> Maybe FormStatus -> Html -> String
renderPage baseUrl lang route maybeStatus content =
  render $
    raw "<!DOCTYPE html>"
      <> el "html" [ attr "lang" (langTag lang) ]
        [ el "head" []
            [ renderHead baseUrl lang route
            , renderPrefetch lang (prefetchFor route)
            ]
        , el "body"
            [ class_ bodyClass ]
            [ Header.render lang route
            , el "main" [ id_ contentTarget, class_ "flex-1 flex flex-col", attr "data-page-title" (routeTitle lang route) ]
                [ maybeStatusBanner lang maybeStatus
                , content
                ]
            , Footer.render lang
            -- Alpine AJAX before Alpine core (plugin must register first)
            -- Pinned versions, self-hosted from /assets/js/ for caching
            -- Nonced via placeholder (replaced at serve time)
            , el "script" [ flag "defer", src "/assets/js/alpine-ajax.min.js", attr "nonce" cspNoncePlaceholder ] []
            , el "script" [ flag "defer", src "/assets/js/alpinejs.min.js", attr "nonce" cspNoncePlaceholder ] []
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
-- | Uses cspNoncePlaceholder; App.Main replaces it at serve time.
renderErrorPage :: Lang -> Int -> String
renderErrorPage lang status =
  let
    d = dict lang
    message = case status of
      404 -> d.common.error404
      _ -> d.common.error500
    content = el "div" [ class_ "mx-auto max-w-3xl px-4 py-16 sm:px-6 lg:px-8 text-center" ]
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white" ] [ text (show status) ]
      , el "p" [ class_ "mt-4 text-lg text-slate-600 dark:text-slate-300" ] [ text message ]
      ]
  in
    render $
      raw "<!DOCTYPE html>"
        <> el "html" [ attr "lang" (langTag lang) ]
          [ el "head" []
              [ el "meta" [ attr "charset" "UTF-8" ] []
              , el "meta" [ attr "name" "viewport", attr "content" "width=device-width, initial-scale=1.0" ] []
              , el "meta" [ name_ "robots", attr "content" "noindex" ] []
              , el "title" [] [ text (show status <> " — " <> d.common.siteTitle) ]
              , el "link" [ attr "rel" "stylesheet", attr "href" "/css/styles.css" ] []
              , el "style" [] [ raw "[x-cloak]{display:none!important}" ]
              , raw ("<script nonce=\"" <> cspNoncePlaceholder <> "\">if(localStorage.getItem('theme')==='dark'||(!localStorage.getItem('theme')&&matchMedia('(prefers-color-scheme:dark)').matches))document.documentElement.classList.add('dark')</script>")
              ]
          , el "body"
              [ class_ bodyClass ]
              [ Header.render lang Home
              , el "main" [ id_ contentTarget, class_ "flex-1 flex flex-col" ]
                  [ content ]
              , Footer.render lang
              , el "script" [ flag "defer", src "/assets/js/alpine-ajax.min.js", attr "nonce" cspNoncePlaceholder ] []
              , el "script" [ flag "defer", src "/assets/js/alpinejs.min.js", attr "nonce" cspNoncePlaceholder ] []
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
-- | Uses raw strings for the shell structure (html/body/main) because the
-- | `el` ADT auto-closes tags. The head and header are rendered via the ADT
-- | (they're complete elements) and embedded as substrings.
renderShellOpen :: String -> Lang -> Route -> String
renderShellOpen baseUrl lang route =
  "<!DOCTYPE html>"
    <> "<html lang=\""
    <> langTag lang
    <> "\">"
    <> render (el "head" [] [ renderHead baseUrl lang route ])
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
-- | Uses cspNoncePlaceholder; App.Main replaces it at serve time.
renderShellClose :: Lang -> Route -> String
renderShellClose lang _ =
  "</main>"
    <> render (Footer.render lang)
    <> render (el "script" [ flag "defer", src "/assets/js/alpine-ajax.min.js", attr "nonce" cspNoncePlaceholder ] [])
    <> render (el "script" [ flag "defer", src "/assets/js/alpinejs.min.js", attr "nonce" cspNoncePlaceholder ] [])
    <> "</body></html>"

-- | Escape attribute values for raw HTML strings. The `el` ADT escapes
-- | automatically; raw strings (renderShellOpen) need manual escaping.


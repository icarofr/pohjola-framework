-- | Alpine.js integration constants and helpers.
-- |
-- | Single source of truth for the SPA-feel layer: swap target IDs, AJAX
-- | detection header, and the `spaLink` helper that bakes in the Alpine
-- | attributes every navigation link needs. Eliminates magic strings
-- | scattered across Header, Footer, and Main.
module App.Alpine where

import Prelude

import App.Html (Attr, Html, attr, el, flag, href)
import Data.I18n (Lang)
import Data.Route (Route, routeUrl)

-- ============================================================================
-- Constants — the contract between server fragments and Alpine AJAX
-- ============================================================================

-- | The DOM element ID that Alpine AJAX swaps on navigation.
-- | Used by: Page.purs (defines the target), spaLink (targets it),
-- | Main.purs (fragment response must contain it).
contentTarget :: String
contentTarget = "content"

-- | The request header that Alpine AJAX sends on click navigation.
-- | The server checks this (AND ?_frag=1 in the URL) to return a fragment
-- | instead of a full page. See App.Main.isFragmentRequest.
alpineRequestHeader :: String
alpineRequestHeader = "x-alpine-request"

-- ============================================================================
-- SPA link helper
-- ============================================================================

-- | Navigation link with Alpine AJAX enhancement.
-- |
-- | Bakes in `x-target.push` (swap the content target) and hover prefetch.
-- | The prefetch sends the `x-alpine-request` header so the server returns
-- | a fragment (not a full page), and the browser caches it — the click
-- | then hits the cache with zero round-trip.
-- |
-- | If JS is disabled, this degrades to a normal `<a>` — the href is real.
-- | Additional attributes (class, aria-label, etc.) can be passed through.
spaLink :: Lang -> Route -> Array Attr -> Array Html -> Html
spaLink lang route extraAttrs children =
  el "a"
    ( [ href (routeUrl lang route)
      , xTargetPush contentTarget
      , prefetchHover
      ] <> extraAttrs
    )
    children

-- ============================================================================
-- Typed Alpine Attribute Constructors
-- ============================================================================

-- | Alpine component state. The expression is a JS object literal.
xData :: String -> Attr
xData = attr "x-data"

-- | Conditional visibility (Alpine x-show). The expression is a JS boolean expression.
xShow :: String -> Attr
xShow = attr "x-show"

-- | Hide element until Alpine initializes (boolean attribute, no value).
xCloak :: Attr
xCloak = flag "x-cloak"

-- | Sync state across Alpine components (boolean attribute).
xSync :: Attr
xSync = flag "x-sync"

-- | Alpine AJAX navigation target. Takes the DOM element ID to swap.
xTargetPush :: String -> Attr
xTargetPush = attr "x-target.push"

-- | Focus management (boolean attribute).
xAutofocus :: Attr
xAutofocus = flag "x-autofocus"

-- | Click handler. The expression is a JS statement.
onClick :: String -> Attr
onClick = attr "@click"

-- | Click-outside handler. The expression is a JS statement.
onClickOutside :: String -> Attr
onClickOutside = attr "@click.outside"

-- | Keydown escape on window. The expression is a JS statement.
onKeydownEscapeWindow :: String -> Attr
onKeydownEscapeWindow = attr "@keydown.escape.window"

-- | Mouseenter handler. The expression is a JS statement.
onMouseenter :: String -> Attr
onMouseenter = attr "@mouseenter"

-- | Bound aria-expanded attribute. The expression is a JS expression.
bindAriaExpanded :: String -> Attr
bindAriaExpanded = attr ":aria-expanded"

-- | Hover prefetch: fetches the fragment (not full page) on mouseenter.
-- | Sends the x-alpine-request header so the server returns a fragment.
-- | The browser caches it; the click then hits the cache with zero round-trip.
prefetchHover :: Attr
prefetchHover = onMouseenter ("fetch($el.href, {headers: {'" <> alpineRequestHeader <> "': 'true'}})")

-- | Container — deep module for horizontal centering + width capping.
-- |
-- | All page-level and section-level width-constrained wrappers flow through
-- | this seam. The `w-full` is load-bearing: `<main>` is a flex column, so
-- | `margin: auto` on the cross axis overrides `align-items: stretch` and
-- | shrinks children to content width. `w-full` restores full width before
-- | `max-w-*` caps it.
-- |
-- | See `docs/conventions/adding-pages.md` for the component architecture.
module App.Ui.Container where

import Prelude

import App.Html (Html, class_, el)

-- | Center content and cap width.
-- |
-- | - `maxWidth` — Tailwind max-width class (e.g. "max-w-3xl", "max-w-7xl")
-- | - `extra` — additional classes (e.g. "py-16", "text-center", "")
container :: String -> String -> Array Html -> Html
container maxWidth extra inner =
  el "div" [ class_ ("mx-auto w-full " <> maxWidth <> " px-4 sm:px-6 lg:px-8 " <> extra) ] inner

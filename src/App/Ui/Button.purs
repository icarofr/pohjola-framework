-- | Button primitive — shadcn-inspired variants, type-safe via sum types
module App.Ui.Button where

import Prelude

import App.Alpine (spaLink)
import App.Html (Html, class_, el, href, rel_, target_, text)
import Data.I18n (Lang)
import Data.Route (Route)

data Variant = Primary | Secondary | Outline | Ghost
data Size = Sm | Md | Lg

renderVariant :: Variant -> String
renderVariant = case _ of
  Primary -> "bg-blue-600 text-white shadow-sm hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600"
  Secondary -> "bg-slate-100 text-slate-900 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-100 dark:hover:bg-slate-700"
  Outline -> "border border-slate-300 text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
  Ghost -> "text-slate-700 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800"

renderSize :: Size -> String
renderSize = case _ of
  Sm -> "px-3 py-1.5 text-xs"
  Md -> "px-3.5 py-2.5 text-sm"
  Lg -> "px-6 py-3 text-base"

baseClass :: String
baseClass = "inline-flex items-center justify-center rounded-md font-semibold transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"

-- | Internal link styled as a button.
-- |
-- | Takes a `Route`, not a `String` href, and delegates to `spaLink` — so the
-- | Alpine navigation attributes are decided in exactly one place
-- | (`App.Alpine`) rather than being duplicated here.
-- |
-- | This previously emitted `xTargetPush` + `prefetchHover` directly, which
-- | made it a second, independent navigation path. Any future change to how
-- | internal navigation works — a route that must use full-document
-- | navigation because it owns browser state with a mount/dispose lifecycle
-- | (ADR-010), say — would have been applied to `spaLink` and silently missed
-- | here. A styled button is still a link; it must not be a different one.
-- |
-- | External links keep their own constructor (`buttonLinkExternal`), which
-- | correctly takes a `String` href and never carries Alpine attributes.
buttonLink :: { variant :: Variant, size :: Size, lang :: Lang, route :: Route, extraClass :: String } -> String -> Html
buttonLink props label =
  spaLink props.lang props.route
    [ class_ (baseClass <> " " <> renderVariant props.variant <> " " <> renderSize props.size <> " " <> props.extraClass) ]
    [ text label ]

-- | Render an external link styled as a button
buttonLinkExternal :: { variant :: Variant, size :: Size, href :: String, extraClass :: String } -> String -> Html
buttonLinkExternal props label =
  el "a"
    [ href props.href
    , target_ "_blank"
    , rel_ "noopener noreferrer"
    , class_ (baseClass <> " " <> renderVariant props.variant <> " " <> renderSize props.size <> " " <> props.extraClass)
    ]
    [ text label ]

-- | Rigid ActionCard layout template with slot constraints and pinned baseline actions
module App.Ui.Layout.ActionCard where

import Prelude

import App.Html (Html, alt, class_, decoding_, el, height_, loading_, src, text, width_)
import App.Ui.Badge (BadgeVariant)
import App.Ui.Badge as Badge
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Layout.Types (ActionTarget(..))
import Data.Maybe (Maybe(..))

type ActionCardProps =
  { tag :: Maybe { text :: String, variant :: BadgeVariant }
  , imageUrl :: Maybe { url :: String, alt :: String, width :: Int, height :: Int }
  , title :: String
  , description :: String
  , action ::
      { label :: String
      , target :: ActionTarget
      }
  }

-- | Render an ActionCard with locked vertical rhythm and pinned button baseline
actionCard :: ActionCardProps -> Html
actionCard props =
  el "div" [ class_ "flex flex-col justify-between h-full p-6 sm:p-7 rounded-lg bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-2xs transition-all hover:border-zinc-300 dark:hover:border-zinc-700" ]
    [ -- Content Area
      el "div" [ class_ "space-y-4" ]
        [ case props.imageUrl of
            Just img ->
              el "div" [ class_ "aspect-16/10 overflow-hidden rounded-md bg-zinc-100 dark:bg-zinc-800 border border-zinc-200/80 dark:border-zinc-800 mb-4" ]
                [ el "img"
                    [ class_ "h-full w-full object-cover"
                    , src img.url
                    , alt img.alt
                    , width_ img.width
                    , height_ img.height
                    , loading_ "lazy"
                    , decoding_ "async"
                    ]
                    []
                ]
            Nothing -> text ""
        , case props.tag of
            Just t -> Badge.badge t.variant t.text
            Nothing -> text ""
        , el "h3" [ class_ "font-display text-lg sm:text-xl font-bold tracking-tight text-zinc-950 dark:text-white" ]
            [ text props.title ]
        , el "p" [ class_ "text-sm leading-relaxed text-zinc-600 dark:text-zinc-400 font-normal" ]
            [ text props.description ]
        ]
    -- Pinned Action Footer
    , el "div" [ class_ "mt-6 pt-4 border-t border-zinc-100 dark:border-zinc-800 flex items-center justify-end" ]
        [ case props.action.target of
            Internal t ->
              buttonLink { variant: ButtonSecondary, size: Sm, lang: t.lang, route: t.route, extraClass: "w-full" } props.action.label
            External t ->
              buttonLinkExternal { variant: ButtonOutline, size: Sm, href: t.href, extraClass: "w-full" } props.action.label
        ]
    ]

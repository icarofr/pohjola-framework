-- | Pure DaisyUI ActionCard layout template
module App.Ui.Layout.ActionCard where

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

-- | Render an ActionCard using DaisyUI card semantics
actionCard :: ActionCardProps -> Html
actionCard props =
  el "div" [ class_ "card bg-base-100 shadow-md border border-base-200 flex flex-col justify-between h-full hover:shadow-lg transition-all" ]
    [ case props.imageUrl of
        Just img ->
          el "figure" [ class_ "aspect-16/10 overflow-hidden bg-base-200" ]
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
    , el "div" [ class_ "card-body flex flex-col justify-between p-6 space-y-4" ]
        [ el "div" [ class_ "space-y-3" ]
            [ case props.tag of
                Just t -> Badge.badge t.variant t.text
                Nothing -> text ""
            , el "h3" [ class_ "card-title text-lg font-bold text-base-content" ]
                [ text props.title ]
            , el "p" [ class_ "text-sm text-base-content/75 leading-relaxed font-normal" ]
                [ text props.description ]
            ]
        , el "div" [ class_ "card-actions justify-end pt-4 border-t border-base-200" ]
            [ case props.action.target of
                Internal t ->
                  buttonLink { variant: ButtonSecondary, size: Sm, lang: t.lang, route: t.route, extraClass: "w-full" } props.action.label
                External t ->
                  buttonLinkExternal { variant: ButtonOutline, size: Sm, href: t.href, extraClass: "w-full" } props.action.label
            ]
        ]
    ]

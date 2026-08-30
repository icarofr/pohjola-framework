-- | Site footer — frozen DESIGN.md dock recipe (not Daisy footer demo).
module App.Ui.Shell.SiteFooter
  ( SiteFooterProps
  , siteFooter
  , siteFooterClass
  , siteFooterGridClass
  , siteFooterLabelClass
  ) where

import Prelude

import App.Alpine (navLink)
import App.Html (Html, class_, el, href, rel_, target_, text)
import App.Ui.Container (container)
import App.Ui.TextTone (TextTone(..), toneClass)
import Data.I18n (Lang)
import Data.Route (Route(..))

type SiteFooterProps =
  { siteTitle :: String
  , siteDescription :: String
  , exploreLabel :: String
  , resourcesLabel :: String
  , aboutLabel :: String
  , contactLabel :: String
  , postsLabel :: String
  , githubLabel :: String
  , issuesLabel :: String
  , lang :: Lang
  , currentRoute :: Route
  }

siteFooterClass :: String
siteFooterClass = "border-t border-base-300 bg-base-100"

siteFooterGridClass :: String
siteFooterGridClass = "grid grid-cols-1 gap-8 py-12 md:grid-cols-3"

siteFooterLabelClass :: String
siteFooterLabelClass = "text-xs font-mono uppercase tracking-widest"

siteFooter :: SiteFooterProps -> Html
siteFooter props =
  el "footer" [ class_ siteFooterClass ]
    [ container "max-w-7xl" "px-4 sm:px-6 lg:px-8 w-full"
        [ el "div" [ class_ siteFooterGridClass ]
            [ el "div" [ class_ "flex flex-col gap-3" ]
                [ el "p" [ class_ (siteFooterLabelClass <> " " <> toneClass Meta) ] [ text props.siteTitle ]
                , el "p" [ class_ "text-sm" ] [ text props.siteDescription ]
                ]
            , el "nav" [ class_ "flex flex-col gap-2" ]
                [ el "p" [ class_ (siteFooterLabelClass <> " " <> toneClass Meta) ] [ text props.exploreLabel ]
                , navLink { lang: props.lang, current: props.currentRoute, target: About } [ class_ "link link-hover text-sm" ] [ text props.aboutLabel ]
                , navLink { lang: props.lang, current: props.currentRoute, target: Contact } [ class_ "link link-hover text-sm" ] [ text props.contactLabel ]
                , navLink { lang: props.lang, current: props.currentRoute, target: PostList } [ class_ "link link-hover text-sm" ] [ text props.postsLabel ]
                ]
            , el "nav" [ class_ "flex flex-col gap-2" ]
                [ el "p" [ class_ (siteFooterLabelClass <> " " <> toneClass Meta) ] [ text props.resourcesLabel ]
                , el "a"
                    [ href "https://github.com/icarofr/pohjola-framework"
                    , target_ "_blank"
                    , rel_ "noopener noreferrer"
                    , class_ "link link-hover text-sm"
                    ]
                    [ text props.githubLabel ]
                , el "a"
                    [ href "https://github.com/icarofr/pohjola-framework/issues"
                    , target_ "_blank"
                    , rel_ "noopener noreferrer"
                    , class_ "link link-hover text-sm"
                    ]
                    [ text props.issuesLabel ]
                ]
            ]
        ]
    ]

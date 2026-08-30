-- | Site footer — DaisyUI footer (research/daisyui-llms.txt).
module App.Layout.Footer where

import App.Alpine (navLink)
import App.Html (Html, class_, el, href, rel_, target_, text)
import Data.Content (siteInfo)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

render :: Lang -> Route -> Html
render lang currentRoute =
  let
    d = dict lang
  in
    el "footer" [ class_ "footer sm:footer-horizontal bg-base-200 p-10" ]
      [ el "nav" []
          [ el "h6" [ class_ "footer-title" ] [ text siteInfo.title ]
          , el "p" [] [ text siteInfo.description ]
          ]
      , el "nav" []
          [ el "h6" [ class_ "footer-title" ] [ text d.footer.explore ]
          , navLink { lang, current: currentRoute, target: About } [ class_ "link link-hover" ] [ text d.nav.about ]
          , navLink { lang, current: currentRoute, target: Contact } [ class_ "link link-hover" ] [ text d.nav.contact ]
          , navLink { lang, current: currentRoute, target: PostList } [ class_ "link link-hover" ] [ text d.nav.posts ]
          ]
      , el "nav" []
          [ el "h6" [ class_ "footer-title" ] [ text d.footer.resources ]
          , el "a"
              [ href "https://github.com/icarofr/pohjola-framework"
              , target_ "_blank"
              , rel_ "noopener noreferrer"
              , class_ "link link-hover"
              ]
              [ text d.footer.github ]
          , el "a"
              [ href "https://github.com/icarofr/pohjola-framework/issues"
              , target_ "_blank"
              , rel_ "noopener noreferrer"
              , class_ "link link-hover"
              ]
              [ text d.footer.issues ]
          ]
      ]

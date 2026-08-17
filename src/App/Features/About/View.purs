-- | About page sections — rebuilt using pure DaisyUI components
module App.Features.About.View where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui as Ui
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))

renderAbout :: Lang -> Html
renderAbout lang =
  let
    d = (dict lang).about
    navDict = (dict lang).nav
  in
    Ui.pageLayout
      { header:
          Ui.pageHeader
            { category: Just navDict.about
            , title: d.heading
            , subtitle: Nothing
            }
      , content:
          el "div" [ class_ "card bg-base-100 shadow-md border border-base-200" ]
            [ el "div" [ class_ "card-body p-8 sm:p-10 space-y-6 text-base sm:text-lg leading-relaxed text-base-content/85 font-normal" ]
                (foldMap (\p -> [ el "p" [] [ text p ] ]) d.paragraphs)
            ]
      }

-- | About page sections — strictly assembled via App.Ui component contracts
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
          el "div" [ class_ "p-8 sm:p-10 rounded-lg bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-2xs space-y-6 text-base sm:text-lg leading-relaxed text-zinc-700 dark:text-zinc-300 font-normal" ]
            (foldMap (\p -> [ el "p" [] [ text p ] ]) d.paragraphs)
      }

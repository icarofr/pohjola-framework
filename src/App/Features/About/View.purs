-- | About page view — strictly rendered via closed EditorialPage blueprint
module App.Features.About.View where

import App.Html (Html, class_, el, text)
import App.Ui as Ui
import App.Ui.Button (ButtonVariant(..))
import Data.Content (bookingUrl)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))

renderAbout :: Lang -> Html
renderAbout lang =
  let
    d = (dict lang).about
    navDict = (dict lang).nav
    contactDict = (dict lang).contact
  in
    Ui.editorialPage
      { category: Just navDict.about
      , title: d.heading
      , subtitle: Nothing
      , body: el "div" [ class_ "space-y-6" ] (foldMap (\p -> [ el "p" [] [ text p ] ]) d.paragraphs)
      , action: Just { label: contactDict.sourceButton, variant: ButtonPrimary, target: Ui.External { href: bookingUrl } }
      }

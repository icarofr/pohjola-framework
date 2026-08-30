-- | About page view — editorial blueprint
module App.Features.About.View where

import App.Html (Html)
import App.Ui as Ui
import App.Ui.Button (ButtonVariant(..))
import Data.Content (bookingUrl)
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
      , body: Ui.editorialParagraphs d.paragraphs
      , action: Just { label: contactDict.sourceButton, variant: ButtonPrimary, target: Ui.External { href: bookingUrl } }
      }

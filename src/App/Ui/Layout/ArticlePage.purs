-- | Article detail — semantic article + prose-lg
module App.Ui.Layout.ArticlePage
  ( ArticlePageBlueprint
  , articlePage
  , authorBylineClass
  , articleTitleClass
  ) where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Avatar as Avatar
import App.Ui.Badge as Badge
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink)
import App.Ui.Container (container)
import App.Ui.Divider as Divider
import App.Ui.Prose (proseLg)
import App.Ui.TextTone (TextTone(..), toneClass)
import Data.I18n (Lang)
import Data.Maybe (Maybe, fromMaybe)
import Data.Route (Route)
import Data.String as String

type ArticlePageBlueprint =
  { back :: { label :: String, lang :: Lang, route :: Route }
  , metaTag :: String
  , title :: String
  , authorName :: String
  , authorSubtitle :: Maybe String
  , body :: String
  }

articleTitleClass :: String
articleTitleClass = "text-3xl sm:text-4xl font-bold tracking-tight"

authorBylineClass :: String
authorBylineClass = "flex items-center gap-3 not-prose"

authorByline :: String -> String -> String -> Html
authorByline initial name subtitle =
  el "div" [ class_ authorBylineClass ]
    [ Avatar.avatarPlaceholder Avatar.Avatar12 initial
    , el "div" []
        ( [ el "p" [ class_ "font-semibold" ] [ text name ] ]
            <>
              if String.length (String.trim subtitle) > 0 then
                [ el "p" [ class_ ("text-sm " <> toneClass Meta) ] [ text subtitle ] ]
              else
                []
        )
    ]

articlePage :: ArticlePageBlueprint -> Html
articlePage page =
  let
    avatarInitial =
      let
        name = String.trim page.authorName
      in
        if String.length name > 0 then String.take 1 name else "?"
    authorSubtitle = fromMaybe "" page.authorSubtitle
  in
    container "max-w-5xl" "py-16 sm:py-24 space-y-6"
      [ buttonLink
          { variant: ButtonGhost
          , size: Sm
          , lang: page.back.lang
          , route: page.back.route
          }
          ("← " <> page.back.label)
      , el "article" [ class_ "max-w-3xl space-y-6" ]
          [ el "header" [ class_ "space-y-4 not-prose" ]
              [ Badge.badgeSized Badge.BadgeSm Badge.BadgePrimary page.metaTag
              , el "h1" [ class_ articleTitleClass ] [ text page.title ]
              , authorByline avatarInitial page.authorName authorSubtitle
              ]
          , Divider.divider
          , proseLg [ el "p" [] [ text page.body ] ]
          ]
      ]

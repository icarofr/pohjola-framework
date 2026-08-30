-- | Frozen blueprint recipes — structural design contract (not primitive demos).
module Test.UiSpec (spec) where

import Prelude

import App.Html (render)
import App.Ui.Layout.ActionCard (actionCard)
import App.Ui.Layout.ArticlePage (articlePage, articleTitleClass, authorBylineClass)
import App.Ui.Layout.EditorialPage (editorialPage, editorialParagraphs)
import App.Ui.Layout.FeedPage (feedPage)
import App.Ui.Layout.Hero (hero)
import App.Ui.Layout.SectionHeader (innerPageHeaderClass)
import App.Ui.Layout.TeaserCard (teaserCard, teaserCardBodyClass, teaserCardReadMoreClass)
import App.Ui.Button (ButtonVariant(..))
import App.Ui.Layout.Types (ActionTarget(..))
import Data.I18n (Lang(..))
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldSatisfy)
import Test.Spec.Assertions.String (shouldContain)

spec :: Spec Unit
spec = do
  describe "App.Ui.Layout blueprints" do
    it "hero uses frozen landing recipe" do
      let
        html =
          render
            ( hero
                { eyebrow: Nothing
                , title: "Landing title"
                , body: "Landing body"
                , primaryAction: { label: "Primary", target: Internal { lang: En, route: Home } }
                , secondaryAction: Nothing
                }
            )
      html `shouldContain` "hero bg-base-100"
      html `shouldContain` "hero-content"
      html `shouldContain` "max-w-3xl"
      html `shouldContain` "btn-primary"
      html `shouldSatisfy` (\h -> not $ String.contains (Pattern "max-w-md") h)
      html `shouldSatisfy` (\h -> not $ String.contains (Pattern "bg-base-200") h)

    it "teaserCard uses linked card-body recipe" do
      let
        html =
          render
            ( teaserCard
                { meta: Just "Article"
                , title: "Sample"
                , excerpt: "Excerpt text"
                , action:
                    { label: "Read"
                    , target: Internal { lang: En, route: PostList }
                    }
                }
            )
      html `shouldContain` "card "
      html `shouldContain` teaserCardBodyClass
      html `shouldContain` "card-title"
      html `shouldContain` teaserCardReadMoreClass
      html `shouldContain` "x-target.push"

    it "editorialPage uses prose-lg on open canvas with divider CTA" do
      let
        html =
          render
            ( editorialPage
                { category: Nothing
                , title: "About"
                , subtitle: Just "Framework overview"
                , body: editorialParagraphs [ "Paragraph one." ]
                , action:
                    Just
                      { label: "Contact"
                      , variant: ButtonPrimary
                      , target: Internal { lang: En, route: Contact }
                      }
                }
            )
      html `shouldContain` "prose prose-lg"
      html `shouldContain` "Paragraph one."
      html `shouldContain` "divider"
      html `shouldContain` "btn-primary"
      html `shouldSatisfy` (\h -> not $ String.contains (Pattern "card-actions") h)

    it "feedPage uses frozen inner-page header shell" do
      let
        html =
          render
            ( feedPage
                { category: Just "Posts"
                , title: "All posts"
                , subtitle: Nothing
                , items: []
                , empty: Just { title: "No posts", description: "Check back later.", action: Nothing }
                }
            )
      html `shouldContain` "All posts"
      html `shouldContain` "No posts"
      html `shouldContain` innerPageHeaderClass
      html `shouldContain` "max-w-5xl"

    it "articlePage omits empty author subtitle" do
      let
        html =
          render
            ( articlePage
                { back: { label: "Back", lang: En, route: PostList }
                , metaTag: "Article 1"
                , title: "Sample post"
                , authorName: "Unknown"
                , authorSubtitle: Nothing
                , body: "Body copy."
                }
            )
      html `shouldContain` authorBylineClass
      html `shouldContain` articleTitleClass
      html `shouldContain` "Unknown"
      html `shouldContain` "divider"
      html `shouldContain` "prose prose-lg"

    it "actionCard hub CTA uses frozen btn-outline variant" do
      let
        html =
          render
            ( actionCard
                { tag: Nothing
                , imageUrl: Nothing
                , title: "Hub"
                , description: "Description"
                , action: { label: "Open", target: External { href: "https://example.com" } }
                }
            )
      html `shouldContain` "btn-outline"

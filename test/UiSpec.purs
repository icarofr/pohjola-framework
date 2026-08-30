-- | Unit tests for accessible UI primitives (Modal, Toast, Accordion, Tabs, Badge, Alert, Stat, EmptyState)
module Test.UiSpec (spec) where

import Prelude

import App.Html (render, text)
import App.Ui (BadgeVariant(..))
import App.Ui.Accordion (renderAccordion)
import App.Ui.Alert as Alert
import App.Ui.Alert (AlertVariant(..))
import App.Ui.Badge as Badge
import App.Ui.EmptyState as EmptyState
import App.Ui.Layout.ActionCard (actionCard)
import App.Ui.Layout.ArticlePage (articlePage, articleTitleClass, authorBylineClass)
import App.Ui.Layout.EditorialPage (editorialPage, editorialParagraphs)
import App.Ui.Layout.FeedPage (feedPage)
import App.Ui.Layout.Hero (hero)
import App.Ui.Layout.SectionHeader (innerPageHeaderClass)
import App.Ui.Layout.TeaserCard (teaserCard, teaserCardBodyClass, teaserCardReadMoreClass)
import App.Ui.Button (ButtonVariant(..))
import App.Ui.Layout.Types (ActionTarget(..))
import App.Ui.Modal (renderModal)
import Data.I18n (Lang(..))
import Data.Route (Route(..))
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Test.Spec.Assertions (shouldSatisfy)
import App.Ui.Stat as Stat
import App.Ui.Tabs (renderTabs)
import App.Ui.Toast (renderToast)
import Data.Maybe (Maybe(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions.String (shouldContain)

spec :: Spec Unit
spec = do
  describe "App.Ui" do
    describe "Modal" do
      it "renders dialog role and aria-modal" do
        let html = render (renderModal { id: "test-modal", triggerText: "Open Modal", title: "Dialog Title", content: text "Modal Content" })
        html `shouldContain` "role=\"dialog\""
        html `shouldContain` "aria-modal=\"true\""
        html `shouldContain` "aria-label=\"Dialog Title\""
        html `shouldContain` "Open Modal"
        html `shouldContain` "Modal Content"

    describe "Toast" do
      it "renders status role and message" do
        let html = render (renderToast { id: "test-toast", message: "Changes saved successfully", isSuccess: true })
        html `shouldContain` "role=\"status\""
        html `shouldContain` "Changes saved successfully"

    describe "Accordion" do
      it "renders accordion group with ARIA controls" do
        let
          items =
            [ { id: "item1", title: "Section 1", content: text "Content 1", defaultOpen: true }
            , { id: "item2", title: "Section 2", content: text "Content 2", defaultOpen: false }
            ]
        let html = render (renderAccordion items)
        html `shouldContain` "aria-controls=\"panel_item1\""
        html `shouldContain` "aria-controls=\"panel_item2\""
        html `shouldContain` "Section 1"
        html `shouldContain` "Content 1"

    describe "Tabs" do
      it "renders tablist and tabpanel roles" do
        let
          tabs =
            { tab1: { id: "tab1", label: "Tab 1", content: text "Panel 1" }
            , tab2: { id: "tab2", label: "Tab 2", content: text "Panel 2" }
            }
        let html = render (renderTabs tabs)
        html `shouldContain` "role=\"tablist\""
        html `shouldContain` "role=\"tab\""
        html `shouldContain` "role=\"tabpanel\""
        html `shouldContain` "Tab 1"
        html `shouldContain` "Panel 1"

    describe "Badge" do
      it "renders badge class with semantic variant" do
        let html = render (Badge.badge BadgeSuccess "Active")
        html `shouldContain` "badge"
        html `shouldContain` "badge-success"
        html `shouldContain` "Active"

    describe "Alert" do
      it "renders alert role and semantic class" do
        let html = render (Alert.alert AlertError "Something broke")
        html `shouldContain` "role=\"alert\""
        html `shouldContain` "alert-error"
        html `shouldContain` "Something broke"

    describe "Stat" do
      it "renders stat card with title and value" do
        let html = render (Stat.statCard { label: "Total Users", value: "1,250", description: Just "+12% this month" })
        html `shouldContain` "Total Users"
        html `shouldContain` "1,250"
        html `shouldContain` "+12% this month"

    describe "EmptyState" do
      it "renders actionable empty state" do
        let html = render (EmptyState.emptyState { title: "No items yet", description: "Get started by creating one.", action: Nothing })
        html `shouldContain` "No items yet"
        html `shouldContain` "Get started by creating one."

      it "uses frozen card recipe not hero slab" do
        let html = render (EmptyState.emptyState { title: "Empty", description: "Nothing here.", action: Nothing })
        html `shouldContain` EmptyState.emptyStateCardClass
        html `shouldContain` EmptyState.emptyStateSectionClass
        html `shouldSatisfy` (\h -> not $ String.contains (Pattern "hero bg-base-200") h)
        html `shouldSatisfy` (\h -> not $ String.contains (Pattern "max-w-md") h)

    describe "Blueprint recipes" do
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

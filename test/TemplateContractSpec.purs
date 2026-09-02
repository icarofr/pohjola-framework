-- | Page template contracts — structural markers enforced per route.
module Test.TemplateContractSpec (spec) where

import Prelude

import App.Features.About.View as About
import App.Features.Contact.View as Contact
import App.Features.Fixtures.View as Fixtures
import App.Features.Home.View as Home
import App.Features.Posts.Types (Post(..))
import App.Features.Posts.View as Posts
import App.Html (render)
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.Form as Form
import App.Ui.Templates.Types (FormField(..))
import Data.Array (length)
import Data.I18n (Lang(..), dict)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))
import Data.String.Common (split) as String
import Data.String.Pattern (Pattern(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Assertions.String as StrAssert

spec :: Spec Unit
spec = do
  describe "TemplateContractSpec" do
    describe "structural markers" do
      it "home exposes landing hero, features, and cta sections" do
        let html = render (Home.renderHome En Nothing)
        StrAssert.shouldContain html (Contract.slot Contract.landingHero)
        StrAssert.shouldContain html (Contract.slot Contract.landingFeatures)
        StrAssert.shouldContain html (Contract.slot Contract.landingCta)
        StrAssert.shouldContain html (Contract.slot Contract.siteHeader)

      it "home features expose three items and section copy" do
        let html = render (Home.renderHome En Nothing)
        countMarker html Contract.landingFeatureItem `shouldEqual` Contract.homeFeatureItemCount
        StrAssert.shouldContain html (dict En).hero.eyebrow
        StrAssert.shouldContain html (dict En).services.sectionEyebrow
        StrAssert.shouldContain html (dict En).services.sectionHeadline
        StrAssert.shouldContain html "md:grid-cols-3"
        StrAssert.shouldContain html "card-border"

      it "contact renders exactly three equal hub cards with unified page header" do
        let html = render (Contact.renderContact En Nothing)
        countMarker html Contract.hubCard `shouldEqual` Contract.contactHubCardCount
        StrAssert.shouldContain html (Contract.slot Contract.pageHeader)
        StrAssert.shouldContain html (Contract.slot Contract.pageHeaderBreadcrumbs)
        StrAssert.shouldContain html (Contract.slot Contract.pageHeaderBody)
        StrAssert.shouldContain html "breadcrumbs"
        StrAssert.shouldContain html "divider"
        StrAssert.shouldContain html "card-body"
        StrAssert.shouldContain html "flex-auto"
        StrAssert.shouldContain html "md:grid-cols-3"

      it "about renders unified page header, mission, and six value items" do
        let html = render (About.renderAbout En Nothing)
        StrAssert.shouldContain html (Contract.slot Contract.pageHeader)
        StrAssert.shouldContain html (dict En).about.subtitle
        StrAssert.shouldContain html (Contract.slot Contract.pageHeaderBreadcrumbs)
        StrAssert.shouldContain html (Contract.slot Contract.editorialMission)
        StrAssert.shouldContain html (Contract.slot Contract.editorialValues)
        countTags html "dt" `shouldEqual` Contract.aboutValueCount

      it "posts list keeps feed card grid shape with unified page header" do
        let
          sample =
            Post
              { id: 1
              , userId: 1
              , title: "Sample post"
              , body: "Excerpt for contract test."
              }
          html = render (Posts.renderPostList En Nothing [ sample ])
        StrAssert.shouldContain html (Contract.slot Contract.feedPage)
        StrAssert.shouldContain html (Contract.slot Contract.feedCard)
        StrAssert.shouldContain html (Contract.slot Contract.pageHeader)
        StrAssert.shouldContain html (Contract.slot Contract.pageHeaderBreadcrumbs)
        StrAssert.shouldContain html "line-clamp-3"
        StrAssert.shouldContain html "Engineering"

      it "fixtures schedule exposes unified header, list, and crest rows" do
        let html = render (Fixtures.renderFixtures En Nothing)
        StrAssert.shouldContain html (Contract.slot Contract.schedulePage)
        StrAssert.shouldContain html (Contract.slot Contract.scheduleList)
        StrAssert.shouldContain html (Contract.slot Contract.pageHeader)
        StrAssert.shouldContain html (Contract.slot Contract.pageHeaderBreadcrumbs)
        countMarker html Contract.scheduleRow `shouldEqual` 9
        StrAssert.shouldContain html "/images/crests/tottenham.svg"

      it "Form template renders fieldset and honeypot without feature class_" do
        let
          slots =
            { title: "Beta"
            , subtitle: Nothing
            , breadcrumbs: []
            , action: "/api/beta-signup"
            , submitLabel: "Join"
            , fields: [ FormEmail { name: "email", label: "Email", required: true } ]
            }
          html = render (Form.renderForm En Home slots)
        StrAssert.shouldContain html (Contract.slot Contract.formPage)
        StrAssert.shouldContain html "name=\"website\""
        StrAssert.shouldContain html "fieldset"

countMarker :: String -> String -> Int
countMarker html value =
  let
    needle = Contract.slot value
  in
    max 0 (length (String.split (Pattern needle) html) - 1)

countTags :: String -> String -> Int
countTags html tag =
  let
    open = "<" <> tag
  in
    max 0 (length (String.split (Pattern open) html) - 1)

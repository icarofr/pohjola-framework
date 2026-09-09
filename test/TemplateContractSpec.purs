-- | Page template contracts — structural markers enforced per route.
-- |
-- | Trimmed for the clean-sheet rebuild (see .scratch/clean-sheet-homepage/):
-- | Contact, Posts, and Fixtures no longer exist, so their old Hub/Feed/
-- | Schedule contract checks are gone with them. Home (Landing) and About
-- | (Editorial) are unchanged in shape. Guarantees moved to Hub and Docs to
-- | the new Notice template specifically so the four pages aren't three
-- | copies of one template with different words — see App.Ui.Templates.Hub
-- | / Notice for why. The Form-template check is kernel-level (a synthetic
-- | slots record, not real page content) and needed only a real route to
-- | pass to `renderForm` — Home still works.
module Test.TemplateContractSpec (spec) where

import Prelude

import App.Features.About.View as About
import App.Features.Docs.View as Docs
import App.Features.Guarantees.View as Guarantees
import App.Features.Home.View as Home
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

      it "about renders unified page header, mission, and six value items" do
        let html = render (About.renderAbout En Nothing)
        StrAssert.shouldContain html (Contract.slot Contract.pageHeader)
        StrAssert.shouldContain html (dict En).about.subtitle
        StrAssert.shouldContain html (Contract.slot Contract.pageHeaderBreadcrumbs)
        StrAssert.shouldContain html (Contract.slot Contract.editorialMission)
        StrAssert.shouldContain html (Contract.slot Contract.editorialValues)
        countTags html "dt" `shouldEqual` Contract.aboutValueCount

      it "guarantees renders a lead paragraph and exactly three cards" do
        -- Not asserting the full `lead` string verbatim — App.Html escapes
        -- apostrophes ("doesn't" -> "doesn&#x27;t"), and the dict copy has
        -- them. A clause-final substring without one is a stable enough
        -- signal that the real lead text rendered, not just the marker.
        let html = render (Guarantees.renderGuarantees En Nothing)
        StrAssert.shouldContain html (Contract.slot Contract.pageHeader)
        StrAssert.shouldContain html (dict En).guarantees.subtitle
        StrAssert.shouldContain html (Contract.slot Contract.hubLead)
        StrAssert.shouldContain html "backed by a real, run-it-yourself check, not a promise."
        countMarker html Contract.hubCard `shouldEqual` Contract.hubCardCount

      it "docs renders a lead paragraph and a six-item numbered roadmap" do
        let html = render (Docs.renderDocs En Nothing)
        StrAssert.shouldContain html (Contract.slot Contract.pageHeader)
        StrAssert.shouldContain html (dict En).docs.subtitle
        StrAssert.shouldContain html (Contract.slot Contract.noticeLead)
        StrAssert.shouldContain html "Until then, the source is the documentation"
        countMarker html Contract.noticeItem `shouldEqual` length (dict En).docs.items

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

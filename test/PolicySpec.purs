-- | Policy enforcement — manifest-driven scans + behavioral reference-page checks.
-- |
-- | Single test suite for conventions that were previously split across Makefile
-- | Theme/string checks in PolicySpec. Fast structural checks run via
-- | scripts/verify-policy.js (same manifest).
module Test.PolicySpec (spec) where

import Prelude

import App.Features.About.View as About
import App.Features.Contact.View as Contact
import App.Features.Home.View as Home
import App.Features.Posts.View as Posts
import App.Layout.Footer as Footer
import App.Layout.Header as Header
import App.Html (render)
import App.Theme (daisyThemeDark, daisyThemeLight, darkModeInitScript)
import App.Ui.Layout.SectionHeader (innerPageHeaderClass)
import App.Ui.Shell.SiteFooter (siteFooterClass)
import App.Ui.Shell.SiteHeader (siteHeaderClass)
import Data.Route (Route(..))
import Data.Array (concat)
import Data.Either (Either(..))
import Data.I18n (Lang(..))
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Data.Traversable (for)
import Effect.Aff (Aff, throwError)
import Effect.Class (liftEffect)
import Effect.Exception (error)
import Test.Policy.Manifest (PolicyManifest, loadManifest)
import Test.Policy.Scan as Scan
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual, shouldSatisfy)
import Test.Spec.Assertions.String as StrAssert

spec :: Spec Unit
spec = do
  describe "PolicySpec" do
    describe "manifest" do
      it "loads policy/manifest.json" do
        manifest <- loadManifest
        case manifest of
          Left err -> fail err
          Right m -> m.version `shouldEqual` 1

      it "theme names match App.Theme module" do
        manifest <- loadManifest
        case manifest of
          Left err -> fail err
          Right m -> do
            m.theme.daisyLight `shouldEqual` daisyThemeLight
            m.theme.daisyDark `shouldEqual` daisyThemeDark

    describe "source scans (manifest)" do
      it "no raw/Raw words in src/" do
        offenders <- Scan.findRawInSrc "src"
        offenders `shouldEqual` []

      it "no banned substrings in src/" do
        manifest <- requireManifest
        offenders <- Scan.findBannedInSrc manifest.bannedSubstrings "src"
        offenders `shouldEqual` []

      it "no foreign import outside allowlist" do
        manifest <- requireManifest
        offenders <- Scan.findForeignImportsOutsideAllowlist manifest.ffiAllowlist "src"
        offenders `shouldEqual` []

      it "no script elements outside allowlist" do
        manifest <- requireManifest
        offenders <- Scan.findScriptsOutsideAllowlist manifest.scriptAllowlist "src"
        offenders `shouldEqual` []

      it "no raw Alpine strings outside App.Alpine" do
        offenders <- Scan.findRawAlpineOutsideAlpine "src"
        offenders `shouldEqual` []

      it "no forbidden patterns in feature views" do
        manifest <- requireManifest
        files <- liftGlob manifest.featureViewPaths
        offenders <- Scan.findForbiddenInFiles manifest.forbiddenInFeatureViews files
        offenders `shouldEqual` []

      it "no forbidden patterns in App.Ui" do
        manifest <- requireManifest
        files <- liftGlob [ "src/App/Ui/**/*.purs", "src/App/Layout/**/*.purs" ]
        offenders <- Scan.findForbiddenInFiles manifest.forbiddenInAppUi files
        offenders `shouldEqual` []

      it "App.Ui class tokens stay on the closed allowlist" do
        manifest <- requireManifest
        unknown <- Scan.findUnknownUiClassTokens manifest.uiClassPolicy.allowedTokens manifest.uiClassPolicy.scanRoot
        unknown `shouldEqual` []

      it "no cross-feature imports" do
        offenders <- Scan.findCrossFeatureImports "src/App/Features"
        offenders `shouldEqual` []

      it "forbidden theme literals absent from src/App" do
        manifest <- requireManifest
        files <- liftGlob [ "src/App/**/*.purs" ]
        offenders <- Scan.findForbiddenInFiles manifest.theme.forbiddenDataThemeLiterals files
        offenders `shouldEqual` []

    describe "theme expressions" do
      it "darkModeInitScript uses manifest theme names" do
        manifest <- requireManifest
        darkModeInitScript `StrAssert.shouldContain` manifest.theme.daisyLight
        darkModeInitScript `StrAssert.shouldContain` manifest.theme.daisyDark

    describe "reference pages (behavioral archetypes)" do
      it "home renders landing hero recipe" do
        let html = render (Home.renderHome En)
        html `StrAssert.shouldContain` "hero bg-base-100"
        html `shouldSatisfy` (\h -> not $ String.contains (Pattern "hero bg-base-200") h)
        html `StrAssert.shouldContain` "https://github.com/icarofr/pohjola-framework"

      it "contact renders hub grid" do
        let html = render (Contact.renderContact En)
        html `StrAssert.shouldContain` "card "
        html `StrAssert.shouldContain` "btn-outline"

      it "about renders editorial prose without card prison" do
        let html = render (About.renderAbout En)
        html `StrAssert.shouldContain` "prose prose-lg"
        html `StrAssert.shouldContain` innerPageHeaderClass

      it "posts list renders feed header shell" do
        let html = render (Posts.renderPostList En [])
        html `StrAssert.shouldContain` innerPageHeaderClass
        html `StrAssert.shouldContain` "card "

    describe "reference shell (behavioral)" do
      it "header renders frozen shell navbar" do
        let html = render (Header.render En Home)
        html `StrAssert.shouldContain` siteHeaderClass
        html `StrAssert.shouldContain` "theme-controller"

      it "footer renders frozen dock grid" do
        let html = render (Footer.render En Home)
        html `StrAssert.shouldContain` siteFooterClass
        html `shouldSatisfy` (\h -> not $ String.contains (Pattern "footer sm:footer-horizontal") h)

requireManifest :: Aff PolicyManifest
requireManifest = do
  result <- loadManifest
  case result of
    Left err -> throwError (error err)
    Right manifest -> pure manifest

liftGlob :: Array String -> Aff (Array String)
liftGlob patterns = do
  batches <- for patterns (\pattern -> liftEffect $ Scan.findFilesMatching pattern)
  pure (concat batches)

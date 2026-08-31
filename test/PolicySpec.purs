-- | Policy enforcement — manifest-driven scans + behavioral reference-page checks.
module Test.PolicySpec (spec) where

import Prelude

import App.Features.About.View as About
import App.Features.Contact.View as Contact
import App.Features.Home.View as Home
import App.Features.Posts.Types (Post(..))
import App.Features.Posts.View as Posts
import App.Html (render)
import App.Theme (themeInitScript, themeDarkName, themeLightName)
import Data.Array (concat, filter)
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

      it "no forbidden patterns in App.Ui (excluding Templates)" do
        manifest <- requireManifest
        files <- liftGlob [ "src/App/Ui/**/*.purs", "src/App/Layout/**/*.purs" ]
        let
          nonTemplateFiles =
            filter (\f -> not (String.contains (Pattern "Ui/Templates") f)) files
        offenders <- Scan.findForbiddenInFiles manifest.forbiddenInAppUi nonTemplateFiles
        offenders `shouldEqual` []

      it "App.Ui.Templates class tokens stay on the closed allowlist" do
        manifest <- requireManifest
        unknown <- Scan.findUnknownUiClassTokens manifest.uiClassPolicy.allowedTokens "src/App/Ui/Templates"
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
      it "themeInitScript applies data-theme without html.dark" do
        themeInitScript `StrAssert.shouldContain` "setAttribute('data-theme'"
        themeInitScript `StrAssert.shouldContain` themeLightName
        themeInitScript `StrAssert.shouldContain` themeDarkName
        themeInitScript `shouldSatisfy` (\s -> not (String.contains (Pattern "classList") s))

    describe "reference pages (page templates)" do
      it "home renders landing hero markers" do
        let html = render (Home.renderHome En)
        html `StrAssert.shouldContain` "text-4xl font-bold"
        html `StrAssert.shouldContain` "bg-base-200"
        html `StrAssert.shouldContain` "https://github.com/icarofr/pohjola-framework"

      it "contact renders three-column hub cards" do
        let html = render (Contact.renderContact En)
        html `StrAssert.shouldContain` "data-template=\"hub-card\""
        html `StrAssert.shouldContain` "md:grid-cols-3"
        html `StrAssert.shouldContain` "flex-auto"

      it "about renders mission and values grid" do
        let html = render (About.renderAbout En)
        html `StrAssert.shouldContain` "Our mission"
        html `StrAssert.shouldContain` "lg:grid-cols-3"

      it "posts list renders feed card grid" do
        let
          sample =
            Post
              { id: 1
              , userId: 1
              , title: "Sample post title"
              , body: "Excerpt body for the card grid."
              }
          html = render (Posts.renderPostList En [ sample ])
        html `StrAssert.shouldContain` "data-template=\"feed-card\""
        html `StrAssert.shouldContain` "line-clamp-3"

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

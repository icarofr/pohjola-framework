-- | Structural policy gate — fast scans from Policy.Contract (make gate).
module Test.Policy.GateSpec (gateSpec) where

import Prelude

import App.Theme (themeInitScript, themeDarkName, themeLightName)
import Data.Array (concat)
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Data.Traversable (for)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Policy.Contract as Policy
import Test.Policy.Scan as Scan
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)
import Test.Spec.Assertions.String as StrAssert

gateSpec :: Spec Unit
gateSpec =
  describe "Policy gate (Policy.Contract)" do
    it "no raw/Raw words in src/" do
      offenders <- Scan.findRawInSrc "src"
      offenders `shouldEqual` []

    it "no banned substrings in src/" do
      offenders <- Scan.findBannedInSrc Policy.bannedSubstrings "src"
      Scan.withoutPolicyExclusions Policy.policyScanExclusions offenders `shouldEqual` []

    it "no foreign import outside allowlist" do
      offenders <- Scan.findForeignImportsOutsideAllowlist Policy.ffiAllowlist "src"
      offenders `shouldEqual` []

    it "no script elements outside allowlist" do
      offenders <- Scan.findScriptsOutsideAllowlist Policy.scriptAllowlist "src"
      offenders `shouldEqual` []

    it "no env read outside allowlist" do
      offenders <- Scan.findEnvReadsOutsideAllowlist Policy.envReadAllowlist "src"
      offenders `shouldEqual` []

    it "no hardcoded copy in feature views" do
      files <- liftGlob Policy.contentFirewallGlobPatterns
      offenders <- Scan.findHardcodedTextInFiles Policy.contentFirewallPattern files
      offenders `shouldEqual` []

    it "no forbidden auth imports in Main or Features" do
      offenders <- Scan.findForbiddenAuthImports
      offenders `shouldEqual` []

    it "isForbiddenAuthImport flags any App.Auth import line" do
      Scan.isForbiddenAuthImport "import App.Auth (requireAuth)" `shouldEqual` true
      Scan.isForbiddenAuthImport "import App.Auth.Scaffold (requireAuth)" `shouldEqual` true
      Scan.isForbiddenAuthImport "import App.Features.Home.View as Home" `shouldEqual` false

    it "no forbidden patterns in feature views" do
      files <- liftGlob Policy.featureViewGlobPatterns
      offenders <- Scan.findForbiddenInFiles Policy.forbiddenInFeatureViews files
      offenders `shouldEqual` []

    it "no forbidden imports in feature views" do
      files <- liftGlob Policy.featureViewGlobPatterns
      offenders <- Scan.findForbiddenImportsInFiles Policy.forbiddenImportsInFeatureViews files
      offenders `shouldEqual` []

    it "no forbidden calls in feature views" do
      files <- liftGlob Policy.featureViewGlobPatterns
      offenders <- Scan.findForbiddenInFiles Policy.forbiddenCallsInFeatureViews files
      offenders `shouldEqual` []

    it "feature views do not concatenate el tags" do
      files <- liftGlob Policy.featureViewGlobPatterns
      offenders <- Scan.findForbiddenInFiles [ "el (" ] files
      offenders `shouldEqual` []

    it "no raw Alpine strings outside App.Alpine" do
      offenders <- Scan.findRawAlpineOutsideAlpine "src"
      offenders `shouldEqual` []

    it "no cross-feature imports" do
      offenders <- Scan.findCrossFeatureImports "src/App/Features"
      offenders `shouldEqual` []

    it "every feature Page has a sibling View.purs" do
      missing <- Scan.findFeaturesMissingView "src/App/Features"
      missing `shouldEqual` []

    it "every feature View imports App.Ui.Templates.Render" do
      missing <- Scan.findFeatureViewsMissingTemplateRender "src/App/Features"
      missing `shouldEqual` []

    it "no extra App.Ui.Templates modules" do
      extras <- Scan.findExtraFiles Policy.uiTemplateModules "src/App/Ui/Templates/*.purs"
      extras `shouldEqual` []

    it "no extra App.Ui primitive modules" do
      extras <- Scan.findExtraFiles Policy.uiPrimitiveModules "src/App/Ui/*.purs"
      extras `shouldEqual` []

    it "text tone seam only in App.Ui.TextTone" do
      offenders <- Scan.findTextToneViolations Policy.textTonePattern Policy.textToneAllowlist "src"
      Scan.withoutPolicyExclusions Policy.policyScanExclusions offenders `shouldEqual` []

    it "forbidden theme literals absent from src/App" do
      files <- liftEffect $ Scan.findFilesMatching "src/App/**/*.purs"
      offenders <- Scan.findForbiddenInFiles Policy.forbiddenThemeLiterals files
      offenders `shouldEqual` []

    it "themeInitScript applies data-theme without html.dark" do
      themeInitScript `StrAssert.shouldContain` "setAttribute('data-theme'"
      themeInitScript `StrAssert.shouldContain` themeLightName
      themeInitScript `StrAssert.shouldContain` themeDarkName
      themeInitScript `shouldSatisfy` (\s -> not (String.contains (Pattern "classList") s))

liftGlob :: Array String -> Aff (Array String)
liftGlob patterns = do
  batches <- for patterns (\pattern -> liftEffect $ Scan.findFilesMatching pattern)
  pure (concat batches)

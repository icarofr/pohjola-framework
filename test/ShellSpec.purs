-- | Frozen site chrome — DaisyUI navbar/footer markers on SiteShell.
module Test.ShellSpec (spec) where

import Prelude

import App.Html (render, text)
import App.Ui.Templates.SiteShell (shellLabels, sitePage)
import Data.I18n (Lang(..))
import Data.Route (Route(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions.String (shouldContain)

spec :: Spec Unit
spec = do
  describe "App.Ui.Templates.SiteShell" do
    it "sitePage uses sticky header, main, and footer markers" do
      let
        labels = shellLabels En
        html =
          render
            ( sitePage En Home labels
                (text "inner")
            )
      html `shouldContain` "sticky top-0 z-50"
      html `shouldContain` "max-w-6xl"
      html `shouldContain` "data-template=\"site-header\""
      html `shouldContain` "data-template=\"site-footer\""
      html `shouldContain` "id=\"content\""
      html `shouldContain` "main class=\"flex-1\""

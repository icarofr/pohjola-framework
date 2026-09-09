-- | Frozen site chrome — DaisyUI navbar/footer markers on App.DatastarShell.
module Test.ShellSpec (spec) where

import Prelude

import App.Datastar (contentTarget)
import App.Features.Home.View as Home
import App.Html (render)
import Data.I18n (Lang(..))
import Data.Maybe (Maybe(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions.String (shouldContain)

spec :: Spec Unit
spec = do
  describe "App.DatastarShell" do
    it "dsSitePage uses sticky header, main, and footer markers" do
      let html = render (Home.renderHome En Nothing)
      html `shouldContain` "sticky top-0 z-50"
      html `shouldContain` "max-w-6xl"
      html `shouldContain` "data-template=\"site-header\""
      html `shouldContain` "data-template=\"site-footer\""
      html `shouldContain` ("id=\"" <> contentTarget <> "\"")
      html `shouldContain` "main class=\"flex-1\""
    it "marks the current route in desktop nav with the brand color" do
      let html = render (Home.renderHome En Nothing)
      html
        `shouldContain`
          ( "href=\"/en\" data-on:click=\"evt.preventDefault(); @get(&#x27;/en&#x27;)\" aria-current=\"page\" class=\"btn btn-ghost btn-sm text-primary font-semibold\""
          )
    it "marks the current route in mobile drawer with the brand color" do
      let html = render (Home.renderHome En Nothing)
      html
        `shouldContain`
          ( "href=\"/en\" data-on:click=\"evt.preventDefault(); @get(&#x27;/en&#x27;)\" aria-current=\"page\" class=\"btn btn-ghost justify-start text-primary font-semibold\""
          )

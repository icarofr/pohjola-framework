-- | Spike-only (datastar-shell-nav-port branch): App.Datastar's rendered
-- | constructor output, mirroring ContractSpec/ShellSpec's App.Alpine
-- | pattern -- asserts the attribute string a constructor produces, not
-- | Datastar's own runtime behavior (that's the e2e seam).
module Test.DatastarSpec (spec) where

import Prelude

import App.Datastar
  ( DsFlag(..)
  , dataPageLangAttr
  , dataPageTitleAttr
  , datastarRequestHeader
  , dsClassWhenEq
  , dsClassWhenFlag
  , dsNavGet
  , dsOnClickOutside
  , dsOnKeydownEscape
  , dsSetFlag
  , dsShowFlag
  , dsShowNotFlag
  , dsSignalsInit
  , dsToggleFlag
  , flagName
  )
import App.Html (render, el, text)
import Data.I18n (Lang(..))
import Data.Route (Route(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Assertions.String as StrAssert

spec :: Spec Unit
spec = do
  describe "App.Datastar" do
    it "constants match the verified Datastar contract" do
      datastarRequestHeader `shouldEqual` "datastar-request"
      dataPageTitleAttr `shouldEqual` "data-page-title"
      dataPageLangAttr `shouldEqual` "data-page-lang"

    it "flagName is stable for every DsFlag" do
      flagName DsThemeMenuOpen `shouldEqual` "themeOpen"
      flagName DsLangMenuOpen `shouldEqual` "langOpen"
      flagName DsDrawerOpen `shouldEqual` "drawerOpen"

    it "dsSignalsInit initializes theme and every flag to false" do
      let html = render (el "div" [ dsSignalsInit ] [])
      html `StrAssert.shouldContain` "data-signals=\""
      html `StrAssert.shouldContain` "themeOpen: false"
      html `StrAssert.shouldContain` "langOpen: false"
      html `StrAssert.shouldContain` "drawerOpen: false"
      html `StrAssert.shouldContain` "localStorage.getItem(&#x27;pohjola-theme&#x27;)"

    it "dsShowFlag/dsShowNotFlag render data-show against the $signal" do
      render (el "div" [ dsShowFlag DsThemeMenuOpen ] [])
        `StrAssert.shouldContain` "data-show=\"$themeOpen\""
      render (el "div" [ dsShowNotFlag DsThemeMenuOpen ] [])
        `StrAssert.shouldContain` "data-show=\"!$themeOpen\""

    it "dsToggleFlag/dsSetFlag render data-on:click assignments" do
      render (el "button" [ dsToggleFlag DsLangMenuOpen ] [])
        `StrAssert.shouldContain` "data-on:click=\"$langOpen = !$langOpen\""
      render (el "button" [ dsSetFlag DsLangMenuOpen false ] [])
        `StrAssert.shouldContain` "data-on:click=\"$langOpen = false\""

    it "dsClassWhenFlag/dsClassWhenEq render data-class bindings" do
      render (el "li" [ dsClassWhenFlag "btn-active" DsThemeMenuOpen ] [])
        `StrAssert.shouldContain` "data-class:btn-active=\"$themeOpen\""
      render (el "li" [ dsClassWhenEq "btn-active" "theme" "dark" ] [])
        `StrAssert.shouldContain` "data-class:btn-active=\"$theme === &#x27;dark&#x27;\""

    it "dsNavGet renders preventDefault + @get to the route's real URL" do
      render (el "a" [ dsNavGet En About ] [ text "About" ])
        `StrAssert.shouldContain` "data-on:click=\"evt.preventDefault(); @get(&#x27;/en/about&#x27;)\""

    it "dsOnClickOutside/dsOnKeydownEscape render the verified event modifiers" do
      render (el "div" [ dsOnClickOutside DsThemeMenuOpen ] [])
        `StrAssert.shouldContain` "data-on:click__outside=\"$themeOpen = false\""
      render (el "div" [ dsOnKeydownEscape DsThemeMenuOpen ] [])
        `StrAssert.shouldContain` "data-on:keydown__window__escape=\"$themeOpen = false\""

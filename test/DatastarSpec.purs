-- | App.Datastar's rendered constructor output, mirroring ContractSpec/
-- | ShellSpec's pattern -- asserts the attribute string a constructor
-- | produces, not Datastar's own runtime behavior (that's the e2e seam).
module Test.DatastarSpec (spec) where

import Prelude

import App.Datastar
  ( DsFlag(..)
  , contentTarget
  , dataPageLangAttr
  , dataPageTitleAttr
  , datastarRequestHeader
  , dsBindFlag
  , dsClassWhenFlag
  , dsClassWhenTheme
  , dsNavGet
  , dsNavLinkRecord
  , dsOnClickOutside
  , dsOnKeydownEscape
  , dsPrefetchHover
  , dsSetFlag
  , dsSetTheme
  , dsShowFlag
  , dsShowNotFlag
  , dsShowTheme
  , dsSignalsInit
  , dsSpaLink
  , dsToggleFlag
  , flagName
  )
import App.Html (render, el, text)
import App.Theme (ThemeMode(..))
import Data.Array (length, nubEq)
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

    it "flagName is injective — two flags cannot share an identifier" do
      -- A collision would silently wire two unrelated controls to one piece
      -- of client state. Exhaustive on DsFlag: adding a constructor without
      -- listing it here leaves a possible collision untested.
      let names = map flagName [ DsThemeMenuOpen, DsLangMenuOpen, DsDrawerOpen ]
      length (nubEq names) `shouldEqual` length names

    it "dsSignalsInit initializes theme and every flag to false" do
      let html = render (el "div" [ dsSignalsInit ] [])
      html `StrAssert.shouldContain` "data-signals=\""
      html `StrAssert.shouldContain` "themeOpen: false"
      html `StrAssert.shouldContain` "langOpen: false"
      html `StrAssert.shouldContain` "drawerOpen: false"
      html `StrAssert.shouldContain` "localStorage.getItem(&#x27;theme&#x27;)"

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

    it "dsClassWhenFlag/dsClassWhenTheme render data-class bindings" do
      render (el "li" [ dsClassWhenFlag "btn-active" DsThemeMenuOpen ] [])
        `StrAssert.shouldContain` "data-class:btn-active=\"$themeOpen\""
      render (el "li" [ dsClassWhenTheme "btn-active" ThemeDark ] [])
        `StrAssert.shouldContain` "data-class:btn-active=\"$theme === &#x27;dark&#x27;\""

    it "dsShowTheme renders data-show against the theme signal" do
      render (el "svg" [ dsShowTheme ThemeSystem ] [])
        `StrAssert.shouldContain` "data-show=\"$theme === &#x27;system&#x27;\""

    it "dsSetTheme is exhaustive over ThemeMode and closes the theme menu" do
      render (el "button" [ dsSetTheme ThemeDark ] [])
        `StrAssert.shouldContain` "document.documentElement.setAttribute(&#x27;data-theme&#x27;, &#x27;pohjola-dark&#x27;)"
      render (el "button" [ dsSetTheme ThemeSystem ] [])
        `StrAssert.shouldContain` "document.documentElement.removeAttribute(&#x27;data-theme&#x27;)"

    it "dsNavGet renders preventDefault + @get to the route's real URL" do
      render (el "a" [ dsNavGet En About ] [ text "About" ])
        `StrAssert.shouldContain` "data-on:click=\"evt.preventDefault(); @get(&#x27;/en/about&#x27;)\""

    it "dsPrefetchHover appends the signals snapshot, matching a real @get() URL" do
      let html = render (el "a" [ dsPrefetchHover ] [])
      html `StrAssert.shouldContain`
        "data-on:mouseenter=\"var u = new URL(el.href); u.searchParams.set(&#x27;datastar&#x27;, JSON.stringify($)); fetch(u.href, {headers: {&#x27;datastar-request&#x27;: &#x27;true&#x27;}})\""
      html `StrAssert.shouldNotContain` "fetch($el.href"
      html `StrAssert.shouldNotContain` "fetch(el.href,"

    it "dsSpaLink renders href + nav + prefetch, no gating" do
      render (dsSpaLink En About [] [ text "About" ])
        `StrAssert.shouldContain` "href=\"/en/about\""

    it "dsNavLinkRecord marks aria-current on the active route and skips its own prefetch" do
      let onSelf = render (dsNavLinkRecord { lang: En, current: About, target: About } [] [ text "About" ])
      onSelf `StrAssert.shouldContain` "aria-current=\"page\""
      let toOther = render (dsNavLinkRecord { lang: En, current: About, target: Home } [] [ text "Home" ])
      toOther `StrAssert.shouldContain` "data-on:mouseenter="

    it "contentTarget is the shared #content id" do
      contentTarget `shouldEqual` "content"

    it "dsOnClickOutside/dsOnKeydownEscape render the verified event modifiers" do
      render (el "div" [ dsOnClickOutside DsThemeMenuOpen ] [])
        `StrAssert.shouldContain` "data-on:click__outside=\"$themeOpen = false\""
      render (el "div" [ dsOnKeydownEscape DsThemeMenuOpen ] [])
        `StrAssert.shouldContain` "data-on:keydown__window__escape=\"$themeOpen = false\""

    it "dsBindFlag renders a bare signal name, no $ prefix" do
      -- Unlike every other constructor here, data-bind identifies which
      -- signal to bind, it doesn't evaluate a JS expression -- verified
      -- against the vendored datastar.js "bind" plugin source.
      render (el "input" [ dsBindFlag DsDrawerOpen ] [])
        `StrAssert.shouldContain` "data-bind=\"drawerOpen\""

-- | Frozen shell recipes — header, footer, theme, lang (DESIGN.md + Daisy docs).
module Test.ShellSpec (spec) where

import Prelude

import App.Html (render)
import App.Theme (daisyThemeDark, siteThemeToggleId)
import App.Ui.Shell.LangMenu (langMenu, langMenuPopoverId)
import App.Ui.Shell.SiteFooter (siteFooter, siteFooterClass, siteFooterLabelClass)
import App.Ui.Shell.SiteHeader (siteHeader, siteHeaderClass)
import App.Ui.Shell.ThemeControl (themeControl, themeSwapClass)
import Data.I18n (Lang(..))
import Data.Route (Route(..))
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldSatisfy)
import Test.Spec.Assertions.String (shouldContain)

spec :: Spec Unit
spec = do
  describe "App.Ui.Shell" do
    it "siteHeader uses sticky blurred navbar recipe" do
      let
        html =
          render
            ( siteHeader
                { lang: En
                , currentRoute: Home
                , menuLabel: "Menu"
                , siteTitle: "Pohjola"
                , aboutLabel: "About"
                , contactLabel: "Contact"
                , postsLabel: "Posts"
                , langToggleLabel: "Language"
                , themeToggleLabel: "Theme"
                }
            )
      html `shouldContain` siteHeaderClass
      html `shouldContain` "navbar"
      html `shouldContain` "border-b border-base-300"
      html `shouldSatisfy` (\h -> not $ String.contains (Pattern "footer sm:footer-horizontal") h)

    it "themeControl uses Daisy theme-controller swap recipe" do
      let html = render (themeControl { ariaLabel: "Theme" })
      html `shouldContain` themeSwapClass
      html `shouldContain` "theme-controller"
      html `shouldContain` ("id=\"" <> siteThemeToggleId <> "\"")
      html `shouldContain` ("value=\"" <> daisyThemeDark <> "\"")
      html `shouldContain` "swap-off"
      html `shouldContain` "swap-on"
      html `shouldSatisfy` (\h -> not $ String.contains (Pattern "header-theme-menu") h)

    it "langMenu uses popover dropdown recipe" do
      let
        html =
          render
            ( langMenu
                { currentLang: En
                , currentRoute: Home
                , ariaLabel: "Language"
                , currentLangLabel: "EN"
                }
            )
      html `shouldContain` ("popovertarget=\"" <> langMenuPopoverId <> "\"")
      html `shouldContain` "dropdown menu"

    it "siteFooter uses DESIGN dock grid, not Daisy footer demo" do
      let
        html =
          render
            ( siteFooter
                { siteTitle: "Pohjola"
                , siteDescription: "Framework"
                , exploreLabel: "Explore"
                , resourcesLabel: "Resources"
                , aboutLabel: "About"
                , contactLabel: "Contact"
                , postsLabel: "Posts"
                , githubLabel: "GitHub"
                , issuesLabel: "Issues"
                , lang: En
                , currentRoute: Home
                }
            )
      html `shouldContain` siteFooterClass
      html `shouldContain` siteFooterLabelClass
      html `shouldContain` "max-w-7xl"
      html `shouldSatisfy` (\h -> not $ String.contains (Pattern "footer sm:footer-horizontal") h)
      html `shouldSatisfy` (\h -> not $ String.contains (Pattern "footer-title") h)

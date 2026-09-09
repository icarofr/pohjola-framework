-- | Theme init — DaisyUI data-theme on <html> before first paint.
module App.Theme
  ( themeInitScript
  , themeLightName
  , themeDarkName
  , themeStorageKey
  , ThemeMode(..)
  , themeModeName
  ) where

import Prelude

themeStorageKey :: String
themeStorageKey = "theme"

themeLightName :: String
themeLightName = "pohjola"

themeDarkName :: String
themeDarkName = "pohjola-dark"

-- | The closed set of theme preferences a visitor can pick. Every client-side
-- | consumer (App.Datastar's typed attribute builders) takes this ADT rather
-- | than an unstructured String, so an invalid mode is a compile error, not a silent
-- | no-op at runtime.
data ThemeMode
  = ThemeLight
  | ThemeDark
  | ThemeSystem

derive instance eqThemeMode :: Eq ThemeMode

instance showThemeMode :: Show ThemeMode where
  show = case _ of
    ThemeLight -> "ThemeLight"
    ThemeDark -> "ThemeDark"
    ThemeSystem -> "ThemeSystem"

themeModeName :: ThemeMode -> String
themeModeName = case _ of
  ThemeLight -> "light"
  ThemeDark -> "dark"
  ThemeSystem -> "system"

themeInitScript :: String
themeInitScript =
  "(function(){var k='"
    <> themeStorageKey
    <> "',l='"
    <> themeLightName
    <> "',d='"
    <> themeDarkName
    <> "',r=document.documentElement,s=localStorage.getItem(k);if(s==='dark')r.setAttribute('data-theme',d);else if(s==='light')r.setAttribute('data-theme',l)})();"

-- | Theme init — DaisyUI data-theme on <html> before first paint.
module App.Theme
  ( themeInitScript
  , themeLightName
  , themeDarkName
  , themeStorageKey
  ) where

import Prelude

themeStorageKey :: String
themeStorageKey = "theme"

themeLightName :: String
themeLightName = "pohjola"

themeDarkName :: String
themeDarkName = "pohjola-dark"

themeInitScript :: String
themeInitScript =
  "(function(){var k='"
    <> themeStorageKey
    <> "',l='"
    <> themeLightName
    <> "',d='"
    <> themeDarkName
    <> "',r=document.documentElement,s=localStorage.getItem(k);if(s==='dark')r.setAttribute('data-theme',d);else if(s==='light')r.setAttribute('data-theme',l)})();"

-- | Theme init — head script + theme-controller checkbox sync (Daisy docs).
module App.Theme
  ( daisyThemeLight
  , daisyThemeDark
  , darkModeInitScript
  , siteThemeToggleId
  ) where

import Prelude

siteThemeToggleId :: String
siteThemeToggleId = "site-theme-toggle"

daisyThemeLight :: String
daisyThemeLight = "pohjola"

daisyThemeDark :: String
daisyThemeDark = "pohjola-dark"

darkModeInitScript :: String
darkModeInitScript =
  "(function(){var light='"
    <> daisyThemeLight
    <> "',dark='"
    <> daisyThemeDark
    <> "',toggleId='"
    <> siteThemeToggleId
    <> "';function apply(isDark){document.documentElement.setAttribute('data-theme',isDark?dark:light);document.documentElement.classList.toggle('dark',isDark);localStorage.setItem('theme',isDark?'dark':'light')}var stored=localStorage.getItem('theme');var prefersDark=matchMedia('(prefers-color-scheme:dark)').matches;var isDark=stored==='dark'||(stored!=='light'&&prefersDark);apply(isDark);document.addEventListener('DOMContentLoaded',function(){var el=document.getElementById(toggleId);if(!el)return;el.checked=isDark;el.addEventListener('change',function(){apply(el.checked)})})})();"

-- | DaisyUI theme names — single source of truth for css/input.css + runtime JS.
-- | Alpine click handlers and head init must use these, not bare "light"/"dark".
module App.Theme
  ( daisyThemeLight
  , daisyThemeDark
  , darkModeInitScript
  ) where

import Prelude

-- | Must match @plugin "daisyui/theme" { name: "pohjola" } in css/input.css.
daisyThemeLight :: String
daisyThemeLight = "pohjola"

-- | Must match @plugin "daisyui/theme" { name: "pohjola-dark" } in css/input.css.
daisyThemeDark :: String
daisyThemeDark = "pohjola-dark"

-- | Inline head script — runs before paint to avoid theme flash.
darkModeInitScript :: String
darkModeInitScript =
  "if(localStorage.getItem('theme')==='dark'||((!localStorage.getItem('theme')||localStorage.getItem('theme')==='system')&&matchMedia('(prefers-color-scheme:dark)').matches)){document.documentElement.classList.add('dark');document.documentElement.setAttribute('data-theme','"
    <> daisyThemeDark
    <> "')}else{document.documentElement.classList.remove('dark');document.documentElement.setAttribute('data-theme','"
    <> daisyThemeLight
    <> "')}"

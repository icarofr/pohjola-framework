-- | Head scripts — closed sum type for the allowlisted inline head scripts (ADR-000)
-- | and the structured JSON-LD script renderer.
module App.Layout.Scripts
  ( HeadScript(..)
  , renderHeadScript
  , renderJsonLdScript
  ) where

import App.Html (Html, attr, el, text)

-- | Closed ADT — only these exact scripts can ever exist inline in <head>.
data HeadScript
  = DarkModeInit
  | TitleSyncPopstateBridge
  | DevLiveReload

-- | Exhaustive interpreter producing the exact, pinned nonced <script> tag.
renderHeadScript :: String -> HeadScript -> Html
renderHeadScript nonce = case _ of
  DarkModeInit ->
    el "script" [ attr "nonce" nonce ]
      [ text "if(localStorage.getItem('theme')==='dark'||((!localStorage.getItem('theme')||localStorage.getItem('theme')==='system')&&matchMedia('(prefers-color-scheme:dark)').matches))document.documentElement.classList.add('dark')" ]

  TitleSyncPopstateBridge ->
    el "script" [ attr "nonce" nonce ]
      [ text "(function(){window.addEventListener(\"ajax:merged\",function(){var m=document.getElementById(\"content\");if(m&&m.dataset.pageTitle)document.title=m.dataset.pageTitle});window.addEventListener(\"popstate\",function(e){if(e.state&&e.state.__ajax)window.location.reload()})})();" ]

  DevLiveReload ->
    el "script" [ attr "nonce" nonce ]
      [ text "if(window.__DEV_RELOAD__||localStorage.getItem('dev_reload')==='true'){var es=new EventSource('/dev/live-reload');es.onerror=function(){setTimeout(function(){location.reload()},1500)}}" ]

-- | Nonced JSON-LD structured data script renderer.
renderJsonLdScript :: String -> String -> Html
renderJsonLdScript nonce json =
  el "script" [ attr "type" "application/ld+json", attr "nonce" nonce ] [ text json ]

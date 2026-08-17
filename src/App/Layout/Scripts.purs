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
  | TitleSync
  | DevLiveReload

-- | Exhaustive interpreter producing the exact, pinned nonced <script> tag.
renderHeadScript :: String -> HeadScript -> Html
renderHeadScript nonce = case _ of
  DarkModeInit ->
    el "script" [ attr "nonce" nonce ]
      [ text "if(localStorage.getItem('theme')==='dark'||((!localStorage.getItem('theme')||localStorage.getItem('theme')==='system')&&matchMedia('(prefers-color-scheme:dark)').matches)){document.documentElement.classList.add('dark');document.documentElement.setAttribute('data-theme','dark')}else{document.documentElement.classList.remove('dark');document.documentElement.setAttribute('data-theme','light')}" ]

  TitleSync ->
    el "script" [ attr "nonce" nonce ]
      [ text "if(!history.state)history.replaceState({__ajax:true},'',location.href);window.addEventListener('ajax:merged',function(){var m=document.getElementById('content');if(m&&m.dataset.pageTitle)document.title=m.dataset.pageTitle;window.scrollTo({top:0,left:0,behavior:'instant'})});window.addEventListener('popstate',function(e){if(e.state&&e.state.__ajax){e.stopImmediatePropagation();fetch(window.location.href,{headers:{'X-Alpine-Request':'true'}}).then(function(r){return r.text()}).then(function(h){var d=new DOMParser().parseFromString(h,'text/html');var nc=d.getElementById('content'),cc=document.getElementById('content');if(nc&&cc){cc.replaceWith(nc);if(nc.dataset.pageTitle)document.title=nc.dataset.pageTitle}var nn=d.getElementById('nav'),cn=document.getElementById('nav');if(nn&&cn)cn.replaceWith(nn);if(window.Alpine)window.Alpine.initTree(document.body);window.scrollTo({top:0,left:0,behavior:'instant'})})}},true);" ]

  DevLiveReload ->
    el "script" [ attr "nonce" nonce ]
      [ text "if(window.__DEV_RELOAD__||localStorage.getItem('dev_reload')==='true'){var es=new EventSource('/dev/live-reload');es.onerror=function(){setTimeout(function(){location.reload()},1500)}}" ]

-- | Nonced JSON-LD structured data script renderer.
renderJsonLdScript :: String -> String -> Html
renderJsonLdScript nonce json =
  el "script" [ attr "type" "application/ld+json", attr "nonce" nonce ] [ text json ]

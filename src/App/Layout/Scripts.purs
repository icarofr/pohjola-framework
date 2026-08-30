-- | Head scripts — closed sum type for the allowlisted inline head scripts (ADR-000)
-- | and the structured JSON-LD script renderer.
module App.Layout.Scripts
  ( HeadScript(..)
  , renderHeadScript
  , renderJsonLdScript
  ) where

import App.Html (Html, attr, el, text)
import App.Theme (darkModeInitScript)

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
      [ text darkModeInitScript ]

  TitleSync ->
    el "script" [ attr "nonce" nonce ]
      [ text "(function(){function sync(){var m=document.getElementById('content');if(m&&m.dataset.pageTitle)document.title=m.dataset.pageTitle}function restore(event){event.stopImmediatePropagation();fetch(location.href,{headers:{'X-Alpine-Request':'true'}}).then(function(r){if(!r.ok)throw new Error('fragment restore failed');return r.text()}).then(function(h){var d=new DOMParser().parseFromString(h,'text/html'),c=d.body.children,nh=c[0],nm=c[1],oh=document.querySelector('header#header[x-sync]'),om=document.querySelector('main#content');if(c.length!==2||!nh||nh.tagName!=='HEADER'||nh.id!=='header'||!nh.hasAttribute('x-sync')||!nm||nm.tagName!=='MAIN'||nm.id!=='content'||!nm.hasAttribute('data-page-title'))throw new Error('invalid navigation fragment');if(oh&&om){oh.replaceWith(nh);om.replaceWith(nm);sync();document.dispatchEvent(new CustomEvent('ajax:merged',{detail:{url:location.href}}));window.scrollTo({top:0,left:0,behavior:'instant'})}})}if(!history.state)history.replaceState({__ajax:true},'',location.href);document.addEventListener('ajax:merged',sync);window.addEventListener('popstate',restore,true);sync()})();" ]

  DevLiveReload ->
    el "script" [ attr "nonce" nonce ]
      [ text "if(window.__DEV_RELOAD__||localStorage.getItem('dev_reload')==='true'){var es=new EventSource('/dev/live-reload');es.onerror=function(){setTimeout(function(){location.reload()},1500)}}" ]

-- | Nonced JSON-LD structured data script renderer.
renderJsonLdScript :: String -> String -> Html
renderJsonLdScript nonce json =
  el "script" [ attr "type" "application/ld+json", attr "nonce" nonce ] [ text json ]

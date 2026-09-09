-- | Head scripts — closed sum type for the allowlisted inline head scripts (ADR-000)
-- | and the structured JSON-LD script renderer.
module App.Layout.Scripts
  ( HeadScript(..)
  , renderHeadScript
  , renderJsonLdScript
  ) where

import Prelude

import App.Alpine (contentTarget, dataPageTitleAttr)
import App.Html (Html, attr, el, text)
import App.Theme (themeInitScript)

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
      [ text themeInitScript ]

  TitleSync ->
    el "script" [ attr "nonce" nonce ]
      [ text pageSyncScript ]

  DevLiveReload ->
    el "script" [ attr "nonce" nonce ]
      [ text "if(window.__DEV_RELOAD__||localStorage.getItem('dev_reload')==='true'){var es=new EventSource('/dev/live-reload');es.onerror=function(){setTimeout(function(){location.reload()},1500)}}" ]

-- | Fragment head-sync: reads data-page-title/data-page-lang from #content
-- | and patches <title>/<html lang> after a fragment swap or history
-- | restore, then scrolls to the top of the new view. Deliberately just
-- | those two fields — the only ones with a real client-side observer
-- | (browser tab title; screen-reader language on navigation). SEO/social
-- | metadata (description, OG, canonical, hreflang) is correct in the
-- | server-rendered <head> on every direct request; crawlers and unfurlers
-- | never execute this script, so it isn't synced here — see App.Alpine's
-- | dataPageTitleAttr/dataPageLangAttr doc.
pageSyncScript :: String
pageSyncScript =
  "(function(){function sync(){var m=document.getElementById('" <> contentTarget <> "');if(!m)return;var d=m.dataset;if(d.pageTitle)document.title=d.pageTitle;if(d.pageLang)document.documentElement.lang=d.pageLang;}function restore(event){event.stopImmediatePropagation();fetch(location.href,{headers:{'X-Alpine-Request':'true'}}).then(function(r){if(!r.ok)throw new Error('fragment restore failed');return r.text()}).then(function(h){var d=new DOMParser().parseFromString(h,'text/html'),n=d.getElementById('" <> contentTarget <> "'),o=document.getElementById('" <> contentTarget <> "');if(!n||!o||n.tagName!=='DIV'||!n.hasAttribute('" <> dataPageTitleAttr <> "'))throw new Error('invalid navigation fragment');o.replaceWith(n);document.dispatchEvent(new CustomEvent('ajax:merged',{detail:{url:location.href}}))})}if(!history.state)history.replaceState({__ajax:true},'',location.href);document.addEventListener('ajax:merged',function(){sync();window.scrollTo({top:0,left:0,behavior:'instant'})});window.addEventListener('popstate',restore,true);sync()})();"

-- | Nonced JSON-LD structured data script renderer.
renderJsonLdScript :: String -> String -> Html
renderJsonLdScript nonce json =
  el "script" [ attr "type" "application/ld+json", attr "nonce" nonce ] [ text json ]

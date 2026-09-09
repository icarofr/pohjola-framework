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
  | DsShellRouter

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

  DsShellRouter ->
    el "script" [ attr "nonce" nonce ]
      [ text dsShellRouterScript ]

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

-- | Spike-only (datastar-shell-nav-port branch): the hand-rolled
-- | pushState/popstate wrapper Datastar itself deliberately doesn't provide
-- | (data-star.dev/docs.md points to plain <a> navigation instead — see
-- | App.Datastar's module doc and spec.md's Implementation Decisions).
-- |
-- | Forward nav: every dsNavGet click fires a real @get(url), and Datastar
-- | dispatches "datastar-fetch" {type:"finished"} on document after the SSE
-- | patch has already been applied to #content (verified against the
-- | vendored datastar.js source: the "finished" dispatch sits in a finally
-- | block after the patch-apply await) — so by the time this fires, the
-- | DOM is already correct; this only needs to pushState + sync + scroll.
-- | The triggering <a>'s real href (event.detail.el) is the only source of
-- | the target URL, since @get(url) itself never touches location.href.
-- |
-- | Back/forward: Datastar has no history awareness at all, so popstate is
-- | wholly hand-rolled here — same shape as App.Alpine's own restore():
-- | re-fetch as a Datastar request, parse the "data: elements " payload out
-- | of the unparsed SSE body, and replace #content wholesale (a full replace,
-- | not Datastar's own morph, matching how Alpine's popstate restore()
-- | already works rather than reimplementing morphing by hand).
dsShellRouterScript :: String
dsShellRouterScript =
  "(function(){function sync(){var m=document.getElementById('"
    <> contentTarget
    <> "');if(!m)return;var d=m.dataset;if(d.pageTitle)document.title=d.pageTitle;if(d.pageLang)document.documentElement.lang=d.pageLang;}function afterPatch(){sync();window.scrollTo({top:0,left:0,behavior:'instant'})}document.addEventListener('datastar-fetch',function(e){if(e.detail.type!=='finished')return;var el=e.detail.el;var href=el&&el.getAttribute&&el.getAttribute('href');if(!href)return;history.pushState({__ds:true},'',href);afterPatch()});function restore(){fetch(location.href,{headers:{'datastar-request':'true'}}).then(function(r){return r.text()}).then(function(sse){var marker='data: elements ';var i=sse.indexOf(marker);if(i===-1)throw new Error('invalid datastar patch event');var html=sse.slice(i+marker.length).split('\n\n')[0];var d=new DOMParser().parseFromString(html,'text/html'),n=d.getElementById('"
    <> contentTarget
    <> "'),o=document.getElementById('"
    <> contentTarget
    <> "');if(!n||!o)throw new Error('invalid navigation fragment');o.replaceWith(n);afterPatch()})}if(!history.state)history.replaceState({__ds:true},'',location.href);window.addEventListener('popstate',restore,true);sync()})();"

-- | Nonced JSON-LD structured data script renderer.
renderJsonLdScript :: String -> String -> Html
renderJsonLdScript nonce json =
  el "script" [ attr "type" "application/ld+json", attr "nonce" nonce ] [ text json ]

-- | Head scripts — closed sum type for the allowlisted inline head scripts (ADR-000)
-- | and the structured JSON-LD script renderer.
module App.Layout.Scripts
  ( HeadScript(..)
  , renderHeadScript
  , renderJsonLdScript
  ) where

import Prelude

import App.Datastar (contentTarget)
import App.Html (Html, attr, el, text)
import App.Theme (themeInitScript)

-- | Closed ADT — only these exact scripts can ever exist inline in <head>
-- | (or, for DsShellRouter, in <body>; see App.DatastarShell.renderDsDocument).
data HeadScript
  = DarkModeInit
  | DevLiveReload
  | DsShellRouter

-- | Exhaustive interpreter producing the exact, pinned nonced <script> tag.
renderHeadScript :: String -> HeadScript -> Html
renderHeadScript nonce = case _ of
  DarkModeInit ->
    el "script" [ attr "nonce" nonce ]
      [ text themeInitScript ]

  DevLiveReload ->
    el "script" [ attr "nonce" nonce ]
      [ text "if(window.__DEV_RELOAD__||localStorage.getItem('dev_reload')==='true'){var es=new EventSource('/dev/live-reload');es.onerror=function(){setTimeout(function(){location.reload()},1500)}}" ]

  DsShellRouter ->
    el "script" [ attr "nonce" nonce ]
      [ text dsShellRouterScript ]

-- | The hand-rolled pushState/popstate wrapper Datastar itself deliberately
-- | doesn't provide (data-star.dev/docs.md points to plain <a> navigation
-- | instead — see App.Datastar's module doc).
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
-- | wholly hand-rolled here: re-fetch as a Datastar request with the same
-- | `?datastar={}` identity hover and `@get({payload: {}})` use, parse the
-- | "data: elements " payload out of the unparsed SSE body, and replace
-- | #content wholesale (a full replace, not Datastar's own morph — simpler
-- | to hand-roll correctly than reimplementing morphing by hand). A non-ok
-- | response (including HTTP 304, whose body is empty), an empty body, or
-- | an unparseable patch each throw; `.catch()` falls back to
-- | `location.reload()` of the URL the browser already committed on this
-- | history traversal, as a real document instead of a silently unhandled
-- | rejection. This handler does not pushState.
dsShellRouterScript :: String
dsShellRouterScript =
  "(function(){function sync(){var m=document.getElementById('"
    <> contentTarget
    <> "');if(!m)return;var d=m.dataset;if(d.pageTitle)document.title=d.pageTitle;if(d.pageLang)document.documentElement.lang=d.pageLang;}function afterPatch(){sync();window.scrollTo({top:0,left:0,behavior:'instant'})}document.addEventListener('datastar-fetch',function(e){if(e.detail.type!=='finished')return;var el=e.detail.el;var href=el&&el.getAttribute&&el.getAttribute('href');if(!href)return;history.pushState({__ds:true},'',href);afterPatch()});function restore(){var u=new URL(location.href);u.searchParams.set('datastar','{}');fetch(u.href,{headers:{'datastar-request':'true'}}).then(function(r){if(!r.ok)throw new Error('datastar restore '+r.status);return r.text()}).then(function(sse){if(!sse)throw new Error('empty datastar patch');var marker='data: elements ';var i=sse.indexOf(marker);if(i===-1)throw new Error('invalid datastar patch event');var html=sse.slice(i+marker.length).split('\\n\\n')[0];var d=new DOMParser().parseFromString(html,'text/html'),n=d.getElementById('"
    <> contentTarget
    <> "'),o=document.getElementById('"
    <> contentTarget
    <> "');if(!n||!o)throw new Error('invalid navigation fragment');o.replaceWith(n);afterPatch()}).catch(function(){location.reload()})}if(!history.state)history.replaceState({__ds:true},'',location.href);window.addEventListener('popstate',restore,true);sync()})();"

-- | Nonced JSON-LD structured data script renderer.
renderJsonLdScript :: String -> String -> Html
renderJsonLdScript nonce json =
  el "script" [ attr "type" "application/ld+json", attr "nonce" nonce ] [ text json ]

-- | Head scripts — closed sum type for the allowlisted inline head scripts (ADR-000)
-- | and the structured JSON-LD script renderer.
module App.Layout.Scripts
  ( HeadScript(..)
  , renderHeadScript
  , renderJsonLdScript
  ) where

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

-- | Fragment head-sync: reads data-page-* from #content and patches <title>,
-- | lang, description, OG, hreflang. Href/OG alternate lists come from
-- | dataset keys derived from allLangs (pageHref* / pageOgAlts) plus
-- | pageHrefDefault from defaultLang for x-default — no hardcoded
-- | language list in this IIFE.
pageSyncScript :: String
pageSyncScript =
  "(function(){function meta(s,v){var e=document.querySelector(s);if(e&&v!=null)e.setAttribute('content',v);}function hrefLink(s,p){var e=document.querySelector(s);if(e&&p)e.setAttribute('href',location.origin+p);}function syncHrefs(d){Object.keys(d).forEach(function(k){if(k.indexOf('pageHref')!==0||k==='pageHrefDefault')return;var tag=k.slice('pageHref'.length).toLowerCase();if(!tag)return;hrefLink('link[rel=\"alternate\"][hreflang=\"'+tag+'\"]',d[k]);});if(d.pageHrefDefault)hrefLink('link[rel=\"alternate\"][hreflang=\"x-default\"]',d.pageHrefDefault);}function syncOgAlts(c,alts){document.querySelectorAll('meta[property=\"og:locale:alternate\"]').forEach(function(n){n.remove();});String(alts||'').split(',').forEach(function(l){if(!l||l===c)return;var m=document.createElement('meta');m.setAttribute('property','og:locale:alternate');m.setAttribute('content',l);document.head.appendChild(m);});}function sync(){var m=document.getElementById('content');if(!m)return;var d=m.dataset,t=d.pageTitle;if(t){document.title=t;meta('meta[property=\"og:title\"]',t);meta('meta[name=\"twitter:title\"]',t);}if(d.pageLang)document.documentElement.lang=d.pageLang;var desc=d.pageDescription;if(desc){meta('meta[name=\"description\"]',desc);meta('meta[property=\"og:description\"]',desc);meta('meta[name=\"twitter:description\"]',desc);}var url=location.href.split('#')[0],canon=document.querySelector('link[rel=\"canonical\"]');if(canon)canon.setAttribute('href',url);meta('meta[property=\"og:url\"]',url);if(d.pageOgLocale){meta('meta[property=\"og:locale\"]',d.pageOgLocale);syncOgAlts(d.pageOgLocale,d.pageOgAlts);}syncHrefs(d);}function restore(event){event.stopImmediatePropagation();fetch(location.href,{headers:{'X-Alpine-Request':'true'}}).then(function(r){if(!r.ok)throw new Error('fragment restore failed');return r.text()}).then(function(h){var d=new DOMParser().parseFromString(h,'text/html'),n=d.getElementById('content'),o=document.getElementById('content');if(!n||!o||n.tagName!=='DIV'||!n.hasAttribute('data-page-title'))throw new Error('invalid navigation fragment');o.replaceWith(n);sync();document.dispatchEvent(new CustomEvent('ajax:merged',{detail:{url:location.href}}));window.scrollTo({top:0,left:0,behavior:'instant'})})}if(!history.state)history.replaceState({__ajax:true},'',location.href);document.addEventListener('ajax:merged',sync);window.addEventListener('popstate',restore,true);sync()})();"

-- | Nonced JSON-LD structured data script renderer.
renderJsonLdScript :: String -> String -> Html
renderJsonLdScript nonce json =
  el "script" [ attr "type" "application/ld+json", attr "nonce" nonce ] [ text json ]

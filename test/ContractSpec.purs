-- | Behavioural invariant tests the compiler cannot express.
-- |
-- | The type system can't see the stringly-typed seams this suite pins:
-- | security header tuples on every Response, the Datastar contentTarget /
-- | data-page-title contract, i18n wildcard fallbacks, the layout shell,
-- | and the total `raw` ban. If a future refactor breaks one of
-- | these contracts, this suite fails loudly instead of misbehaving in
-- | production.
-- |
-- | Route-literal coverage that needs more than one route to be meaningful
-- | (nav-link active-vs-inactive contrast, JSON-LD route-kind dispatch,
-- | dynamic-cache-key collision) is still pending — see
-- | .scratch/clean-sheet-homepage/, ticket 02+ — and returns as About/
-- | Guarantees/Docs are wired in.
module Test.ContractSpec where

import Prelude

import App.DatastarShell (dsActiveNavClass, dsDropdownItemClass, dsDropdownItemClasses, dsDropdownPanelClass, dsSiteErrorPage)
import App.Datastar (contentTarget, dsSpaLink)
import App.Theme (themeDarkName, themeLightName)
import App.Config (Config)
import App.Features.Home.View as Home
import App.Form (FormStatus(..), contactFields, newsletterFields)
import App.Layout.Head (escapeJson, renderJsonLd)
import App.Layout.Page (renderErrorFragment, renderErrorPage, renderDocument, renderShellOpen, renderShellClose, renderPrefetch)
import App.Main (pageRenderer)
import App.Server (RedirectKind(..), Response, cspWithNonce, errorStatusCode, fileResponse, htmlErrorResponse, internalError, methodNotAllowed, notFound, notModified, ok, okText, okTextPublic, okWith, redirect, redirectVary, securityHeaders, tooManyRequests)
import App.Html (render)
import Data.Array (find, last, mapMaybe)
import Data.Content (services)
import Data.Either (Either(..))
import Data.Foldable (any, for_)
import Data.I18n (Lang(..), dict)
import Data.Maybe (Maybe(..), isJust)
import Data.Route (Route(..), allLangs, staticRoutes)
import Data.Email (EmailAddress, defaultEmailAddress)
import Data.Tuple (Tuple(..), snd)
import Effect.Aff (Aff)
import App.Bun (readTextFile)
import Policy.Contract as Policy
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldNotEqual, shouldSatisfy)
import Test.Spec.Assertions.String as StrAssert

-- ============================================================================
-- Helpers
-- ============================================================================

-- | Config stub for render tests — static pages never read any field; the
-- | data-backed routes are excluded from `staticRoutes` so `postsApiBase`
-- | is never hit. Kept inline so the spec needs no env at all.
stubConfig :: Config
stubConfig =
  { port: 3000
  , staticRoot: "dist"
  , baseUrl: "https://example.com"
  , resendApiKey: Nothing
  , emailFrom: testEmail "noreply@example.com"
  , emailTo: testEmail "contact@example.com"
  , postsApiBase: "https://example.com"
  , rateLimitMax: 0
  , rateLimitWindowMs: 60000.0
  , databaseUrl: Nothing
  , secureCookies: true
  }

testEmail :: String -> EmailAddress
testEmail = defaultEmailAddress

-- | Full SSR document for a static route, composed from the feature page
-- | module (pure content) through the Layout.Page shell. The `Left` branch
-- | is unreachable (callers pass `staticRoutes`) but keeps the match total.
renderStaticPage :: Route -> Lang -> Aff String
renderStaticPage route lang = do
  result <- pageRenderer stubConfig route lang Nothing
  pure case result of
    Right html -> renderDocument stubConfig.baseUrl "test-nonce-123" lang route html
    Left _ -> ""

-- | True when a headers array contains a header with the given name.
hasHeader :: String -> Array (Tuple String String) -> Boolean
hasHeader key headers = any (\(Tuple k _) -> k == key) headers

-- | Extract the CSP value from a headers array.
cspValue :: Array (Tuple String String) -> Maybe String
cspValue headers = snd <$> find (\(Tuple k _) -> k == "Content-Security-Policy") headers

-- | The LAST value for a header key — mirrors the Bun bridge, which applies
-- | headers with `Headers.set` in iteration order, so a later duplicate wins.
lastHeaderValue :: String -> Response -> Maybe String
lastHeaderValue key response =
  last (mapMaybe (\(Tuple k v) -> if k == key then Just v else Nothing) response.headers)

-- | Extract the Cache-Control value from a response.
cacheControl :: Response -> Maybe String
cacheControl response = snd <$> find (\(Tuple k _) -> k == "Cache-Control") response.headers

-- | Assert a response carries the non-negotiable security headers (excluding
-- | CSP, which is injected per-request by `serve` via `withCsp`).
checkSecurityHeaders :: Response -> Aff Unit
checkSecurityHeaders response = do
  response.headers `shouldSatisfy` hasHeader "X-Content-Type-Options"
  response.headers `shouldSatisfy` hasHeader "Strict-Transport-Security"

-- | Pinned CSP template. The actual CSP includes a per-request nonce, so we
-- | pin the static parts and test the nonce injection separately. If you ever
-- | widen the CSP, update this test deliberately — and justify it in the
-- | commit message. See App.Server.cspWithNonce.
expectedCspPrefix :: String
expectedCspPrefix =
  "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'nonce-"

expectedCspSuffix :: String
expectedCspSuffix =
  "' 'self' 'unsafe-eval' 'strict-dynamic'"

-- | The JS-side 500-fallback CSP (no nonce — text/plain, no scripts execute).
expectedFallbackCsp :: String
expectedFallbackCsp =
  "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-eval'"

-- ============================================================================
-- Specs
-- ============================================================================

spec :: Spec Unit
spec = do
  describe "ContractSpec" do
    describe "form field canonical names" do
      it "contactFields defines canonical field names" do
        let fields = [ contactFields.name, contactFields.email, contactFields.message, contactFields.website, contactFields.lang ]
        for_ fields \f ->
          f `shouldNotEqual` ""
      it "newsletterFields defines canonical field names" do
        let fields = [ newsletterFields.email, newsletterFields.website, newsletterFields.lang ]
        for_ fields \f ->
          f `shouldNotEqual` ""

  describe "security headers on every Response constructor" do
    it "ok" $ checkSecurityHeaders (ok "body")
    it "okWith" $ checkSecurityHeaders (okWith [] "body")
    it "okText" $ checkSecurityHeaders (okText "text/plain; charset=utf-8" "body")
    it "okTextPublic" $ checkSecurityHeaders (okTextPublic "text/plain; charset=utf-8" "body")
    it "htmlErrorResponse" $ checkSecurityHeaders (htmlErrorResponse "body" [] (errorStatusCode 500))
    it "notFound" $ checkSecurityHeaders notFound
    it "methodNotAllowed" $ checkSecurityHeaders methodNotAllowed
    it "internalError" $ checkSecurityHeaders internalError
    it "redirect" $ checkSecurityHeaders (redirect Found "/en")
    it "redirectVary" $ checkSecurityHeaders (redirectVary Found "/en" [])
    it "tooManyRequests" $ checkSecurityHeaders (tooManyRequests 60.0)
    it "notModified" $ checkSecurityHeaders (notModified [])
    it "fileResponse" do
      let buf = ""
      checkSecurityHeaders (fileResponse "text/css" buf)

  describe "CSP exact value" do
    it "cspWithNonce produces the pinned policy with nonce" do
      -- Brittle BY DESIGN: if you widened the CSP, update this test
      -- deliberately — and justify it in the commit message.
      let csp = cspWithNonce "test-nonce-123"
      csp `shouldEqual` (expectedCspPrefix <> "test-nonce-123" <> expectedCspSuffix)

    it "securityHeaders no longer carries CSP (per-request nonce injection)" do
      -- CSP is injected by `serve` via cspWithNonce, not in securityHeaders.
      -- securityHeaders must NOT contain a CSP entry.
      cspValue securityHeaders `shouldEqual` Nothing

    it "FFI 500-fallback CSP matches the pinned fallback policy" do
      -- The JS-side last-resort 500 carries its own CSP string (App.ServerBun.js).
      -- It's the fallback policy (no nonce — text/plain, no scripts execute).
      -- A drift here means the containment path serves a different CSP.
      jsSource <- readTextFile "src/App/ServerBun.js"
      case jsSource of
        Right src -> src `StrAssert.shouldContain` ("Content-Security-Policy\": \"" <> expectedFallbackCsp)
        Left err -> StrAssert.shouldContain "" ("expected file to be readable: " <> err)

  describe "Datastar seam — contentTarget" do
    it "every static page renders div#content on the DatastarShell drawer for allLangs" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          html `StrAssert.shouldContain` ("id=\"" <> contentTarget <> "\"")

    it "rendered pages contain no em dashes" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          html `StrAssert.shouldNotContain` "—"
      renderErrorPage "test-nonce-123" En 404 `StrAssert.shouldNotContain` "—"
      renderErrorPage "test-nonce-123" En 500 `StrAssert.shouldNotContain` "—"

    it "full documents carry the template page shell" do
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain` "data-template=\"site-header\""
      html `StrAssert.shouldContain` "sticky top-0 z-50"
      html `StrAssert.shouldContain` "id=\"content\""
      html `StrAssert.shouldContain` "data-page-title"
      html `StrAssert.shouldContain` "<!DOCTYPE html"
      html `StrAssert.shouldContain` "<script"

  describe "Datastar seam — data-page-title" do
    it "every static page renders data-page-title in both languages" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          html `StrAssert.shouldContain` "data-page-title"

  describe "Datastar seam — attribute literals" do
    it "nav links carry data-on:click @get pointing at a route URL" do
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain` "data-on:click=\"evt.preventDefault(); @get("

  describe "FFI allowlist has one meaning" do
    -- Policy.Contract is the single source of truth; Test.Gate scans src/
    -- against the same list. This test only guards contract ↔ docs drift.
    it "Policy.Contract lists the four FFI modules" do
      Policy.ffiAllowlist `shouldEqual`
        [ "src/App/ServerBun.purs"
        , "src/App/FetchBun.purs"
        , "src/App/Bun.purs"
        , "src/App/Data/SQL.purs"
        ]

  describe "SQL migration affinity (ADR-009 Phase 3A)" do
    it "App.Data.SQL exposes reserve and release at the FFI boundary" do
      js <- readTextFile "src/App/Data/SQL.js"
      case js of
        Left err -> StrAssert.shouldContain "" ("expected SQL.js to be readable: " <> err)
        Right source -> do
          source `StrAssert.shouldContain` "reserveImpl"
          source `StrAssert.shouldContain` "releaseImpl"
          source `StrAssert.shouldContain` ".release()"
    it "App.Migration runs on a reserved connection with an advisory lock" do
      ps <- readTextFile "src/App/Migration.purs"
      case ps of
        Left err -> StrAssert.shouldContain "" ("expected Migration.purs to be readable: " <> err)
        Right source -> do
          source `StrAssert.shouldContain` "migrateOnPool"
          source `StrAssert.shouldContain` "reserve"
          source `StrAssert.shouldContain` "pg_advisory_lock"
          source `StrAssert.shouldContain` "pg_advisory_unlock"
          source `StrAssert.shouldContain` "COMMIT failed"
    it "ADR-009 documents reserve-based migration affinity" do
      adr <- readTextFile "docs/adr/ADR-009-bun-sql-data-layer.md"
      case adr of
        Left err -> StrAssert.shouldContain "" ("expected ADR-009 to be readable: " <> err)
        Right source -> do
          source `StrAssert.shouldContain` "reserve"
          source `StrAssert.shouldContain` "pg_advisory_lock"

  describe "the success cache policy rests on a checked premise" do
    -- The policy is documented as `private` because a full page embeds a
    -- per-request CSP nonce. That premise is true for pages and FALSE for
    -- Datastar SSE patches, which carry no nonce at all — they take
    -- `private` as a conservative default, not a requirement. Both facts are
    -- pinned here so the justification cannot quietly stop matching the code.
    it "a full page carries a nonce" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          html `StrAssert.shouldContain` "nonce=\"test-nonce-123\""
    it "a patch's shell content carries NO nonce" do
      -- The SSE-patch body is exactly the same #content shell a full page
      -- embeds, minus the surrounding <head>/<script> — so there is nothing
      -- to nonce. If a nonce ever appears here, the patch cache policy needs
      -- rethinking and this test forces that conversation.
      for_ allLangs \lang -> do
        let frag = render (Home.renderHome lang Nothing)
        frag `StrAssert.shouldNotContain` "nonce="

  describe "form status in fragment" do
    it "Home with FormSuccess renders data-form-status inside #content" do
      let html = render (Home.renderHome En (Just FormSuccess))
      html `StrAssert.shouldContain` "data-form-status"
      html `StrAssert.shouldContain` ("id=\"" <> contentTarget <> "\"")

  describe "patch responses are patch-shaped" do
    it "the shell content is a full template page div#content, no document wrapper" do
      let frag = render (Home.renderHome En Nothing)
      frag `StrAssert.shouldContain` "id=\"content\""
      frag `StrAssert.shouldContain` "data-template=\"site-header\""
      frag `StrAssert.shouldContain` "sticky top-0 z-50"
      frag `StrAssert.shouldNotContain` "<!DOCTYPE"
      frag `StrAssert.shouldNotContain` "<html"
      frag `StrAssert.shouldNotContain` "<script"

    -- A patch response morphs #content via Datastar. If an error path
    -- answers with a full document, the client's SSE parser fails on it
    -- (it isn't one event). ADR-007 states this principle for the streaming
    -- path; the same principle applies here.
    it "the error fragment is not a full document" do
      for_ allLangs \lang -> do
        let frag = renderErrorFragment lang 500
        frag `StrAssert.shouldNotContain` "<!DOCTYPE"
        frag `StrAssert.shouldNotContain` "<html"
        frag `StrAssert.shouldNotContain` "<body"
    it "the error fragment carries the patch target so Datastar can morph it" do
      let frag = renderErrorFragment En 404
      frag `StrAssert.shouldContain` ("id=\"" <> contentTarget <> "\"")
    it "error fragment is a DatastarShell drawer with data-page-title" do
      let html = renderErrorFragment En 404
      html `StrAssert.shouldContain` ("id=\"" <> contentTarget <> "\"")
      html `StrAssert.shouldContain` "data-page-title"
      html `StrAssert.shouldContain` "data-template=\"site-header\""
      html `StrAssert.shouldNotContain` "<!DOCTYPE"
    it "the error fragment shows the status and localized message" do
      let frag = renderErrorFragment En 404
      frag `StrAssert.shouldContain` "404"
      frag `StrAssert.shouldContain` (dict En).common.error404
    it "the full error page remains a complete document" do
      -- The non-fragment path must NOT be changed by the above.
      let full = renderErrorPage "nonce123" En 500
      full `StrAssert.shouldContain` "<!DOCTYPE"
      full `StrAssert.shouldContain` "<html"
    it "dsSiteErrorPage (App.DatastarShell) is what renderErrorFragment wraps" do
      -- renderErrorFragment delegates to dsSiteErrorPage — pinned directly so
      -- the two can't silently diverge behind App.Layout.Page's re-export.
      render (dsSiteErrorPage En 404) `shouldEqual` renderErrorFragment En 404

  describe "error responses are never stored" do
    -- htmlCacheControl's max-age exists so a hover prefetch can be reused by
    -- the click. On an error that is exactly wrong: a transient 502 would stick
    -- in the browser for ten seconds, so a retry after the upstream recovered
    -- would still be answered from cache. Errors are the one class where
    -- staleness is never acceptable — retrying exists to get a different answer.
    it "every HTML error response is no-store" do
      for_ [ 404, 500, 502 ] \status ->
        cacheControl (htmlErrorResponse "<p>x</p>" [] (errorStatusCode status)) `shouldEqual` Just "no-store"
    it "the plain-text error constructors are no-store too" do
      -- These previously carried no cache policy at all, so error caching was
      -- inconsistent three ways. tooManyRequests was missed on the first pass
      -- because the list was enumerated by hand rather than taken from the
      -- constructors that actually exist — it is included explicitly here.
      for_ [ notFound, methodNotAllowed, internalError, tooManyRequests 30.0 ] \r ->
        cacheControl r `shouldEqual` Just "no-store"
    it "the enumerated non-2xx constructors are all no-store" do
      -- NOTE ON SCOPE: this list is hand-maintained. It cannot detect a NEW
      -- response constructor added without a policy — an earlier version of
      -- this comment claimed it could, which was false. It pins the
      -- constructors named here and nothing more. The redirects are included
      -- because their policy is now a decision (see App.Server.redirectVary),
      -- not an omission.
      let
        nonSuccessResponses =
          [ notFound
          , methodNotAllowed
          , internalError
          , tooManyRequests 30.0
          , redirect SeeOther "/en"
          , redirectVary Found "/en" [ Tuple "Vary" "Accept-Language" ]
          , htmlErrorResponse "x" [] (errorStatusCode 404)
          , htmlErrorResponse "x" [] (errorStatusCode 500)
          , htmlErrorResponse "x" [] (errorStatusCode 502)
          ]
      for_ nonSuccessResponses \r -> do
        (r.status >= 300) `shouldEqual` true
        cacheControl r `shouldEqual` Just "no-store"
    it "a caller cannot override the SUCCESS cache policy either" do
      -- okWith previously emitted htmlCacheControl before caller headers, so a
      -- caller-supplied Cache-Control won. That was the same override defect
      -- fixed for the error and redirect constructors and left behind here.
      lastHeaderValue "Cache-Control" (okWith [ Tuple "Cache-Control" "public, max-age=3600" ] "<p>x</p>")
        `shouldEqual` Just "private, max-age=10"
      lastHeaderValue "Cache-Control" (ok "<p>x</p>")
        `shouldEqual` Just "private, max-age=10"

    it "redirect status and cache policy are derived together, per kind" do
      -- The previous design took a policy AND a bare Int status, so a public
      -- policy was pairable with a request-dependent 302, and a non-3xx status
      -- was expressible. Deriving both from the
      -- kind makes those combinations unrepresentable rather than merely
      -- undocumented — HTTP already fixes the pairing.
      let
        check kind status policy = do
          (redirect kind "/en").status `shouldEqual` status
          lastHeaderValue "Cache-Control" (redirect kind "/en") `shouldEqual` Just policy
      check MovedPermanently 301 "public, max-age=3600"
      check PermanentRedirect 308 "public, max-age=3600"
      check Found 302 "no-store"
      check SeeOther 303 "no-store"
      check TemporaryRedirect 307 "no-store"
    it "every redirect kind emits a 3xx status" do
      -- The status is no longer a caller-supplied Int, so a non-redirect
      -- status cannot reach a redirect response at all.
      for_ [ MovedPermanently, PermanentRedirect, Found, SeeOther, TemporaryRedirect ] \k -> do
        ((redirect k "/en").status >= 300) `shouldEqual` true
        ((redirect k "/en").status < 400) `shouldEqual` true
    it "a caller cannot override the error cache policy" do
      -- SCOPE: this asserts TUPLE ORDERING on the PureScript response — it
      -- models the Bun bridge (which applies headers with Headers.set in
      -- iteration order, so the last duplicate wins) rather than exercising it.
      -- A bridge change could break the runtime policy while this stays green.
      -- The emitted header is asserted end-to-end in
      -- e2e/prefetch-cache.spec.js; this test covers the ordering that bridge
      -- consumes.
      let hostile = htmlErrorResponse "x" [ Tuple "Cache-Control" "public, max-age=3600" ] (errorStatusCode 500)
      lastHeaderValue "Cache-Control" hostile `shouldEqual` Just "no-store"
      lastHeaderValue "Cache-Control" (redirectVary Found "/en" [ Tuple "Cache-Control" "public" ])
        `shouldEqual` Just "no-store"
    it "errorStatusCode clamps anything outside 400..599" do
      -- Clamps, does not reject — the signature is total, so there is no
      -- failure channel. Boundaries matter: an earlier version bounded only the
      -- lower end, so 600 and 999 passed straight through to
      -- `new Response(…, { status })` at the Bun boundary.
      --
      -- Asserted through the RESPONSE status rather than an unwrapping
      -- accessor. `unErrorStatus` existed only for this test and leaked the
      -- representation the opacity claim is about; the status a client
      -- actually receives is the observable that matters.
      let statusOf n = (htmlErrorResponse "x" [] (errorStatusCode n)).status
      for_ [ 200, 302, 399, 600, 999, -1 ] \n -> statusOf n `shouldEqual` 500
      for_ [ 400, 404, 500, 502, 599 ] \n -> statusOf n `shouldEqual` n
    it "successful pages keep the reusable policy" do
      -- The error rule must not leak into the success path, which is what makes
      -- the click cache hit possible at all.
      cacheControl (okWith [] "<p>x</p>") `shouldEqual` Just "private, max-age=10"

  describe "nonce-bearing HTML is never shared-cached (W6)" do
    -- Every HTML response embeds a per-request CSP nonce. A shared cache
    -- storing one would replay a single visitor's nonce to everyone else,
    -- leaving CSP structurally intact but hollow. `private` is the guard.
    it "okWith carries Cache-Control: private" do
      cacheControl (okWith [] "<p>x</p>") `shouldEqual` Just "private, max-age=10"
    it "robots.txt and sitemap.xml are publicly cacheable" do
      -- okTextPublic serves nonce-free public documents with shared-cache policy.
      cacheControl (okTextPublic "text/plain" "User-agent: *") `shouldEqual` Just "public, max-age=86400"

  describe "nav link chrome classes" do
    it "desktop active uses the brand color, not a neutral fill" do
      dsActiveNavClass "btn btn-ghost btn-sm" true `shouldEqual` "btn btn-ghost btn-sm text-primary font-semibold"
    it "desktop inactive omits the active treatment" do
      dsActiveNavClass "btn btn-ghost btn-sm" false `shouldEqual` "btn btn-ghost btn-sm"
    it "mobile active uses the brand color, not a neutral fill" do
      dsActiveNavClass "btn btn-ghost justify-start" true `shouldEqual` "btn btn-ghost justify-start text-primary font-semibold"
    it "mobile inactive omits the active treatment" do
      dsActiveNavClass "btn btn-ghost justify-start" false `shouldEqual` "btn btn-ghost justify-start"
    it "desktop dropdown items use the same ghost-button recipe" do
      dsDropdownItemClasses false `shouldEqual` "btn btn-ghost btn-sm w-full justify-start"
      dsDropdownItemClasses true `shouldEqual` "btn btn-ghost btn-sm w-full justify-start btn-active"

    it "the rendered page does not prefetch its own route" do
      -- The Home nav link on the Home page: aria-current, then straight to
      -- class — no data-on:mouseenter prefetch attribute in between, unlike
      -- every other (non-current) nav link.
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain`
        "href=\"/en\" data-on:click=\"evt.preventDefault(); @get(&#x27;/en&#x27;)\" aria-current=\"page\" class=\"btn btn-ghost btn-sm text-primary font-semibold\""

  describe "no external script src" do
    -- PostList/PostDetail are data-backed (network fetch at render time)
    -- and are excluded — see `staticRoutes`. The one script tag must
    -- stay self-hosted (/assets/js/…); an external CDN src is a regression.
    it "static pages only reference self-hosted scripts" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          html `StrAssert.shouldNotContain` "src=\"http"

    it "static pages contain only the pinned inline scripts (ADR-000)" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          StrAssert.shouldContain html "setAttribute('data-theme'"
          StrAssert.shouldContain html themeLightName
          StrAssert.shouldContain html themeDarkName
          -- The shell-router glue: forward nav pushes state after Datastar's
          -- own "finished" event, and popstate re-fetches + replaces #content.
          StrAssert.shouldContain html "document.addEventListener('datastar-fetch',function(e){if(e.detail.type!=='finished')return;"
          StrAssert.shouldContain html "history.pushState({__ds:true},'',href);afterPatch()"
          StrAssert.shouldContain html "document.documentElement.lang=d.pageLang"
          StrAssert.shouldContain html "window.addEventListener('popstate',restore,true);"
          StrAssert.shouldContain html "if(!history.state)history.replaceState({__ds:true},'',location.href)"
          html `StrAssert.shouldContain` "var es=new EventSource('/dev/live-reload')"

  describe "pages flow through the layout shell" do
    it "every static page is a full document with a footer" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          html `StrAssert.shouldContain` "<!DOCTYPE html"
          html `StrAssert.shouldContain` "<footer"

  describe "Bun.serve migration invariants" do
    it "dsSpaLink includes @mouseenter fragment prefetch with el (not $el, not this)" do
      let html = render (dsSpaLink En Home [] [])
      -- Single quotes are escaped to &#x27; in the attribute value;
      -- the browser un-escapes them before Datastar evaluates the expression.
      -- `el` (no `$`): `$el` compiles to a signal lookup in Datastar, not
      -- the element reference — a real bug this pinned after being caught
      -- live (see App.Datastar.dsPrefetchHover's doc comment).
      html `StrAssert.shouldContain` "data-on:mouseenter=\"fetch(el.href, {headers: {&#x27;datastar-request&#x27;: &#x27;true&#x27;}})\""
      html `StrAssert.shouldNotContain` "fetch(this.href)"
      html `StrAssert.shouldNotContain` "fetch($el.href"

    it "renderPrefetch emits <link rel=\"prefetch\">" do
      let html = render (renderPrefetch En [ Home ])
      html `StrAssert.shouldContain` "rel=\"prefetch\""
      html `StrAssert.shouldContain` "/en"

    it "renderJsonLd returns Just for Home" do
      isJust (renderJsonLd "https://example.com" "test-nonce" En Home) `shouldEqual` true

    it "JSON-LD is XSS-safe" do
      -- The security invariant: < must be escaped as \u003c in JSON-LD
      -- content to prevent </script> injection. Test the actual rendered
      -- output, not just the escapeJson helper.
      escapeJson "<" `shouldEqual` "\\u003c"
      escapeJson "</script>" `shouldEqual` "\\u003c/script>"

    it "renderShellOpen produces valid HTML structure" do
      let html = renderShellOpen "https://example.com" "test-nonce-123" En Home
      html `StrAssert.shouldContain` "<!DOCTYPE html"
      html `StrAssert.shouldContain` "bg-base-100"
      html `StrAssert.shouldNotContain` "</body></html>"

    it "renderShellClose closes the document" do
      let html = renderShellClose "test-nonce-123" En Home
      html `StrAssert.shouldContain` "</body></html>"

    it "escapeJson escapes in correct order" do
      -- Backslash must be escaped before quotes to avoid malformed JSON
      escapeJson "\\" `shouldEqual` "\\\\"
      escapeJson "\"" `shouldEqual` "\\\""

  describe "serviceCopy non-fallback coverage" do
    it "every service has non-empty title, description, and action label in both languages" do
      for_ [ services.one, services.two, services.three ] \service ->
        for_ allLangs \lang -> do
          let copy = (dict lang).services.serviceCopy service.id
          copy.title `shouldNotEqual` ""
          copy.description `shouldNotEqual` ""
          copy.actionLabel `shouldNotEqual` ""

  describe "Datastar seam — chrome invariants" do
    it "mobile nav uses DaisyUI drawer" do
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain` "drawer drawer-end"
      html `StrAssert.shouldContain` "drawer-toggle"
      html `StrAssert.shouldContain` "drawer-side"
      html `StrAssert.shouldContain` "id=\"site-drawer\""
    it "theme switcher uses Datastar disclosure in navbar" do
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain` "themeOpen: false"
      html `StrAssert.shouldContain` "aria-haspopup=\"menu\""
      html `StrAssert.shouldContain` "data-show=\"$themeOpen\""
      html `StrAssert.shouldContain` ("setAttribute(&#x27;data-theme&#x27;, &#x27;" <> themeLightName <> "&#x27;)")
      html `StrAssert.shouldContain` "dropdown dropdown-end"
    it "language switcher uses Datastar disclosure in navbar" do
      html <- renderStaticPage Home En
      -- Must be a distinct signal, not the substring inside themeOpen: false.
      html `StrAssert.shouldContain` "themeOpen: false, langOpen: false"
      html `StrAssert.shouldContain` "data-show=\"$langOpen\""
      html `StrAssert.shouldContain` "$langOpen = !$langOpen"
    it "theme and language dropdowns share one item and panel recipe" do
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain` dsDropdownPanelClass
      html `StrAssert.shouldNotContain` "mt-3 w-44 bg-base-100"
      html `StrAssert.shouldContain` dsDropdownItemClass
      html `StrAssert.shouldContain` dsDropdownItemClasses true
    it "language switcher uses route links in marketing header" do
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain` "/en"
      html `StrAssert.shouldContain` "/fr"
      html `StrAssert.shouldContain` "/pt"
      html `StrAssert.shouldContain` "English"
      html `StrAssert.shouldContain` "Français"
      html `StrAssert.shouldContain` "Português"
      html `StrAssert.shouldContain` "href=\"/fr\" data-on:click=\"evt.preventDefault(); @get(&#x27;/fr&#x27;)\""
      html `StrAssert.shouldContain` "data-page-lang"
    it "template pages use bg-base-100 content wrapper" do
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain` "bg-base-100"
      html `StrAssert.shouldContain` "id=\"content\""

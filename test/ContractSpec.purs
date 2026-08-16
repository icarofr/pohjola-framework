-- | Behavioural invariant tests the compiler cannot express.
-- |
-- | The type system can't see the stringly-typed seams this suite pins:
-- | security header tuples on every Response, the Alpine contentTarget /
-- | data-page-title contract, i18n wildcard fallbacks, the layout shell,
-- | and the total `raw` ban. If a future refactor breaks one of
-- | these contracts, this suite fails loudly instead of misbehaving in
-- | production.
module Test.ContractSpec where

import Prelude

import App.Alpine (Flag(..), ThemeMode(..), contentTarget, cycleTheme, flagName, navLink, renderExpr, setFlag, setTheme, spaLink, themeToggle, toggleFlag)
import App.Config (Config)
import App.Form (contactFields, newsletterFields)
import App.Layout.Head (renderJsonLd, escapeJson)
import App.Layout.Page (renderErrorFragment, renderErrorPage, renderFragment, renderPage, renderShellOpen, renderShellClose, renderPrefetch)
import App.Main (pageRenderer)
import App.Server (RedirectKind(..), Response, cspWithNonce, errorStatusCode, fileResponse, htmlErrorResponse, internalError, methodNotAllowed, notFound, ok, okText, okWith, redirect, redirectVary, securityHeaders, tooManyRequests)
import App.Cache (insertDynamic, lookupDynamic, mkDynamicCache)
import App.Html (render, text)
import Data.Array (concat, filter, find, last, length, mapMaybe, nub, uncons)
import Data.Char (toCharCode)
import Data.Content (services)
import Data.Either (Either(..))
import Data.Foldable (any, for_)
import Data.I18n (Lang(..), dict)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Route (Route(..), allLangs, allRoutes, routeUrl)
import Data.Email (EmailAddress(..), mkEmailAddress)
import Data.String.CodeUnits (fromCharArray, stripPrefix, toCharArray) as CodeUnits
import Data.String.Common (split, replaceAll) as Common
import Data.String.Pattern (Pattern(..), Replacement(..))
import Data.Traversable (for)
import Data.Tuple (Tuple(..), snd)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import App.Bun (glob, readTextFile)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldNotEqual, shouldSatisfy)
import Test.Spec.Assertions.String as StrAssert

-- ============================================================================
-- Helpers
-- ============================================================================

-- | Static routes: allRoutes minus the data-backed ones. PostList (and the
-- | dynamic PostDetail, which isn't in allRoutes) fetch from the network at
-- | render time — they're excluded here so the tests never hit the wire.
staticRoutes :: Array Route
staticRoutes = filter (not <<< isDataBacked) allRoutes
  where
  isDataBacked PostList = true
  isDataBacked (PostDetail _) = true
  isDataBacked _ = false

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
  }

testEmail :: String -> EmailAddress
testEmail s = fromMaybe (EmailAddress "fallback@example.com") (mkEmailAddress s)

-- | Full SSR document for a static route, composed from the feature page
-- | module (pure content) through the Layout.Page shell. The `Left` branch
-- | is unreachable (callers pass `staticRoutes`) but keeps the match total.
renderStaticPage :: Route -> Lang -> Aff String
renderStaticPage route lang = do
  result <- pageRenderer stubConfig route lang
  pure case result of
    Right html -> renderPage stubConfig.baseUrl "test-nonce-123" lang route Nothing html
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

-- | Recursively collect every .purs file under a directory.
pursFilesUnder :: String -> Effect (Array String)
pursFilesUnder dir = glob (dir <> "/**/*.purs")

-- | Mirror of the Makefile gate's `grep \braw\b`: true when "raw" appears as
-- | a whole word (bounded by non-word chars or string edges). ASCII word
-- | chars are enough — the source is ASCII.
containsRawWord :: String -> Boolean
containsRawWord str =
  let
    spaced = CodeUnits.fromCharArray (map spaceOut (CodeUnits.toCharArray str))
  in
    any (\w -> w == "raw" || w == "Raw") (Common.split (Pattern " ") spaced)
  where
  spaceOut c = if isWordChar c then c else ' '

isWordChar :: Char -> Boolean
isWordChar c =
  let
    n = toCharCode c
  in
    (n >= 48 && n <= 57) -- 0-9

      || (n >= 65 && n <= 90) -- A-Z
      || (n >= 97 && n <= 122) -- a-z
      || n == 95 -- _

-- | True when a string contains any of the banned patterns.
containsBanned :: String -> Boolean
containsBanned str =
  let
    banned = [ "unsafeCoerce", "unsafePerformEffect", "unsafePartial", "unsafeCompare", "unsafeIndex", "fromJust", "throwException", "catchException", "Data.Maybe.Unsafe", "Data.Array.Unsafe", "Data.String.CodePoint.Unsafe", "Data.String.Unsafe", "Data.Unsafe", "Effect.Unsafe", "Partial" ]
  in
    any (\b -> length (Common.split (Pattern b) str) > 1) banned

-- | True when a string contains raw Alpine attribute patterns.
containsRawAlpine :: String -> Boolean
containsRawAlpine str =
  let
    banned = [ "attr \"x-", "attr \"@", "attr \":", "flag \"x-" ]
  in
    any (\b -> length (Common.split (Pattern b) str) > 1) banned

-- | True when a string contains "foreign import".
containsForeignImport :: String -> Boolean
containsForeignImport str =
  length (Common.split (Pattern "foreign import") str) > 1

-- | Files in src/ containing a forbidden raw/Raw word.
findRawInSrc :: String -> Aff (Array String)
findRawInSrc root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    content <- readTextFile file
    pure
      ( case content of
          Right c -> if containsRawWord c then Just file else Nothing
          Left _ -> Nothing
      )
  pure (mapMaybe identity results)

-- | Files in src/ containing banned functions.
findBannedInSrc :: String -> Aff (Array String)
findBannedInSrc root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    content <- readTextFile file
    pure
      ( case content of
          Right c -> if containsBanned c then Just file else Nothing
          Left _ -> Nothing
      )
  pure (mapMaybe identity results)

-- | Files in src/ containing foreign imports outside allowlist.
findForeignImportsOutsideAllowlist :: String -> Aff (Array String)
findForeignImportsOutsideAllowlist root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    if any (_ == file) ffiAllowlist then pure Nothing
    else do
      content <- readTextFile file
      pure
        ( case content of
            Right c -> if containsForeignImport c then Just file else Nothing
            Left _ -> Nothing
        )
  pure (mapMaybe identity results)

scriptAllowlist :: Array String
scriptAllowlist = [ "src/App/Layout/Scripts.purs", "src/App/Layout/Page.purs" ]

-- | Files in src/ containing `el "script"` outside Layout allowlist.
findScriptsOutsideAllowlist :: String -> Aff (Array String)
findScriptsOutsideAllowlist root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    if any (_ == file) scriptAllowlist then pure Nothing
    else do
      content <- readTextFile file
      pure
        ( case content of
            Right c -> if length (Common.split (Pattern "el \"script\"") c) > 1 then Just file else Nothing
            Left _ -> Nothing
        )
  pure (mapMaybe identity results)

-- | Modules permitted to carry `foreign import`.
-- |
-- | This list is duplicated in the Makefile's `FFI_ALLOWLIST_GREP`, because the
-- | gate runs as grep before the compiler exists. Two sources of truth is a
-- | drift risk, so "the FFI allowlist matches the Makefile gate" below asserts
-- | they agree — adding a module to one and not the other fails the suite.
ffiAllowlist :: Array String
ffiAllowlist = [ "src/App/ServerBun.purs", "src/App/FetchBun.purs", "src/App/Bun.purs", "src/App/Data/SQL.purs" ]

-- | The Makefile's allowlist pattern, escaped the way Make writes it:
-- | `src/App/Bun.purs` → `^src/App/Bun\.purs`
makefilePattern :: String -> String
makefilePattern path = "^" <> Common.replaceAll (Pattern ".") (Replacement "\\.") path

-- | Files in src/ (excluding App.Alpine) containing raw Alpine attribute strings.
findRawAlpineOutsideAlpine :: String -> Aff (Array String)
findRawAlpineOutsideAlpine root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    if file == "src/App/Alpine.purs" then pure Nothing
    else do
      content <- readTextFile file
      pure
        ( case content of
            Right c -> if containsRawAlpine c then Just file else Nothing
            Left _ -> Nothing
        )
  pure (mapMaybe identity results)

-- | Feature name from a module path, e.g. "App.Features.Posts.Types" → "Posts".
featureOfModule :: String -> Maybe String
featureOfModule modName = do
  rest <- CodeUnits.stripPrefix (Pattern "App.Features.") modName
  map (_.head) (uncons (Common.split (Pattern ".") rest))

-- | Feature name from a file path, e.g. "src/App/Features/Posts/Service.purs"
-- | → "Posts".
featureOfPath :: String -> Maybe String
featureOfPath path = do
  rest <- CodeUnits.stripPrefix (Pattern "src/App/Features/") path
  map (_.head) (uncons (Common.split (Pattern "/") rest))

-- | Cross-feature imports: a feature module importing a sibling feature's
-- | module. Returns "<file>: <import line>" for each violation.
findCrossFeatureImports :: String -> Aff (Array String)
findCrossFeatureImports featuresRoot = do
  files <- liftEffect $ pursFilesUnder featuresRoot
  offenders <- for files \file -> do
    content <- readTextFile file
    pure $ case content of
      Left _ -> []
      Right c -> map (\imp -> file <> ": " <> imp) (crossFeatureImports file c)
  pure (concat offenders)
  where
  crossFeatureImports :: String -> String -> Array String
  crossFeatureImports file content =
    case featureOfPath file of
      Nothing -> []
      Just ownFeature ->
        mapMaybe (siblingImport ownFeature) (Common.split (Pattern "\n") content)

  -- | An "import App.Features.X.Y …" line is a violation when X ≠ ownFeature.
  siblingImport :: String -> String -> Maybe String
  siblingImport ownFeature line =
    case CodeUnits.stripPrefix (Pattern "import App.Features.") line of
      Nothing -> Nothing
      Just rest ->
        if featureOfModule ("App.Features." <> rest) == Just ownFeature then Nothing
        else Just line

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
    it "htmlErrorResponse" $ checkSecurityHeaders (htmlErrorResponse "body" [] (errorStatusCode 500))
    it "notFound" $ checkSecurityHeaders notFound
    it "methodNotAllowed" $ checkSecurityHeaders methodNotAllowed
    it "internalError" $ checkSecurityHeaders internalError
    it "redirect" $ checkSecurityHeaders (redirect Found "/en")
    it "redirectVary" $ checkSecurityHeaders (redirectVary Found "/en" [])
    it "tooManyRequests" $ checkSecurityHeaders (tooManyRequests 60.0)
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

  describe "Alpine seam — contentTarget" do
    it "every static page renders <main id=contentTarget> in both languages" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          html `StrAssert.shouldContain` ("id=\"" <> contentTarget <> "\"")

  describe "Alpine seam — data-page-title" do
    it "every static page renders data-page-title in both languages" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          html `StrAssert.shouldContain` "data-page-title"

  describe "Alpine seam — attribute literals" do
    it "head carries the x-cloak style reset" do
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain` "[x-cloak]{display:none!important}"
    it "nav links carry x-target.push pointing at contentTarget" do
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain` "x-target.push=\"content\""

  describe "FFI allowlist has one meaning" do
    -- The gate greps the Makefile pattern; this spec scans with its own list.
    -- Two representations of one contract drift silently unless something
    -- compares them, and a module allowlisted in only one place is either an
    -- unchecked foreign import or a false gate failure.
    it "every allowlisted module appears in the Makefile gate pattern" do
      mk <- readTextFile "Makefile"
      case mk of
        Left err -> StrAssert.shouldContain "" ("expected Makefile to be readable: " <> err)
        Right content -> for_ ffiAllowlist \path ->
          content `StrAssert.shouldContain` makefilePattern path
    it "the Makefile gate pattern allows nothing beyond this list" do
      mk <- readTextFile "Makefile"
      case mk of
        Left err -> StrAssert.shouldContain "" ("expected Makefile to be readable: " <> err)
        Right content -> do
          let
            gateLine = fromMaybe "" $ find (\l -> length (Common.split (Pattern "FFI_ALLOWLIST_GREP :=") l) > 1)
              (Common.split (Pattern "\n") content)
            entries = length (Common.split (Pattern "^src/") gateLine) - 1
          entries `shouldEqual` length ffiAllowlist

  describe "the success cache policy rests on a checked premise" do
    -- The policy is documented as `private` because a full page embeds a
    -- per-request CSP nonce. That premise is true for pages and FALSE for AJAX
    -- fragments, which carry no nonce at all — they take `private` as a
    -- conservative default, not a requirement. Both facts are pinned here so
    -- the justification cannot quietly stop matching the code.
    it "a full page carries a nonce" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          html `StrAssert.shouldContain` "nonce=\"test-nonce-123\""
    it "a fragment carries NO nonce" do
      -- renderFragment emits no <script> tags, so there is nothing to nonce.
      -- If a nonce ever appears here, the fragment cache policy needs
      -- rethinking and this test forces that conversation.
      for_ allLangs \lang -> do
        let frag = renderFragment lang Home (text "content")
        frag `StrAssert.shouldNotContain` "nonce="

  describe "fragment responses are fragment-shaped" do
    -- A fragment response is swapped into #content by Alpine AJAX. If an error
    -- path answers with a full document, the client nests a complete
    -- <!DOCTYPE> document inside the page body. ADR-007 states this principle
    -- for the streaming path; it was never applied to the AJAX error path.
    it "the error fragment is not a full document" do
      for_ allLangs \lang -> do
        let frag = renderErrorFragment lang Home 500
        frag `StrAssert.shouldNotContain` "<!DOCTYPE"
        frag `StrAssert.shouldNotContain` "<html"
        frag `StrAssert.shouldNotContain` "<body"
    it "the error fragment carries the swap target so Alpine can replace it" do
      let frag = renderErrorFragment En Home 404
      frag `StrAssert.shouldContain` ("id=\"" <> contentTarget <> "\"")
    it "the error fragment shows the status and localized message" do
      let frag = renderErrorFragment En Home 404
      frag `StrAssert.shouldContain` "404"
      frag `StrAssert.shouldContain` (dict En).common.error404
    it "the full error page remains a complete document" do
      -- The non-fragment path must NOT be changed by the above.
      let full = renderErrorPage "nonce123" En 500
      full `StrAssert.shouldContain` "<!DOCTYPE"
      full `StrAssert.shouldContain` "<html"

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

  describe "dynamic cache keys cannot collide" do
    -- The key was a rendered string resting on Show Route being injective — a
    -- hand-written instance with nothing enforcing it. It is now the (Route,
    -- Lang) pair, so Ord Route (derived) makes distinct routes distinct keys.
    -- Note allRoutes deliberately EXCLUDES PostDetail, which is the only route
    -- that reaches the dynamic cache — so a test over allRoutes alone would
    -- exercise none of the keys this cache actually stores.
    it "distinct (route, lang) pairs are distinct keys, including PostDetail" do
      let
        detailRoutes = [ PostDetail 1, PostDetail 2, PostDetail 42 ]
        pairs = do
          route <- allRoutes <> detailRoutes
          lang <- allLangs
          pure (Tuple route lang)
      length (nub pairs) `shouldEqual` length pairs
    it "PostDetail ids do not alias each other" do
      (Tuple (PostDetail 1) En == Tuple (PostDetail 2) En) `shouldEqual` false
    it "two entries in the real cache cannot be retrieved through each other" do
      -- Tuple inequality is an argument; this is evidence. Inserts two entries
      -- and proves a lookup of one cannot return the other, across both the
      -- id axis and the lang axis.
      cache <- liftEffect mkDynamicCache
      liftEffect $ insertDynamic cache (Tuple (PostDetail 1) En) (text "one") 60000.0
      liftEffect $ insertDynamic cache (Tuple (PostDetail 2) En) (text "two") 60000.0
      liftEffect $ insertDynamic cache (Tuple (PostDetail 1) Fr) (text "un") 60000.0
      got1 <- liftEffect $ lookupDynamic cache (Tuple (PostDetail 1) En)
      got2 <- liftEffect $ lookupDynamic cache (Tuple (PostDetail 2) En)
      gotFr <- liftEffect $ lookupDynamic cache (Tuple (PostDetail 1) Fr)
      missing <- liftEffect $ lookupDynamic cache (Tuple (PostDetail 9) En)
      map render got1 `shouldEqual` Just "one"
      map render got2 `shouldEqual` Just "two"
      map render gotFr `shouldEqual` Just "un"
      map render missing `shouldEqual` Nothing

  describe "nonce-bearing HTML is never shared-cached (W6)" do
    -- Every HTML response embeds a per-request CSP nonce. A shared cache
    -- storing one would replay a single visitor's nonce to everyone else,
    -- leaving CSP structurally intact but hollow. `private` is the guard.
    it "okWith carries Cache-Control: private" do
      cacheControl (okWith [] "<p>x</p>") `shouldEqual` Just "private, max-age=10"
    it "no successful HTML response is publicly cacheable" do
      -- The exact string is pinned above; this guards the property that matters
      -- even if the max-age is later tuned. htmlErrorResponse is excluded because
      -- every one of its callers is an error — see "error responses are never
      -- stored", which pins no-store for those.
      for_ [ ok "<p>x</p>", okWith [] "<p>x</p>" ] \r ->
        (cacheControl r >>= CodeUnits.stripPrefix (Pattern "private")) `shouldNotEqual` Nothing
    it "robots.txt and sitemap.xml are NOT marked private" do
      -- okText serves nonce-free public documents; marking them private would
      -- stop shared caches serving them for no benefit.
      cacheControl (okText "text/plain" "User-agent: *") `shouldEqual` Nothing

  describe "nav links never prefetch the page already shown" do
    -- After an AJAX swap the header re-renders, and the link for the current
    -- route lands under the user's stationary cursor. Without this, mouseenter
    -- fires again and prefetches the page already on screen — one wholly
    -- redundant request per navigation, measured in e2e/prefetch-cache.spec.js.
    it "the active nav link carries no hover prefetch" do
      let
        active = render (navLink { lang: En, current: About, target: About } [] [])
        other = render (navLink { lang: En, current: About, target: Contact } [] [])
      active `StrAssert.shouldNotContain` "@mouseenter"
      other `StrAssert.shouldContain` "@mouseenter"
    it "the active nav link still navigates and still swaps" do
      -- Dropping the prefetch must not turn it into a dead link.
      let active = render (navLink { lang: En, current: About, target: About } [] [])
      active `StrAssert.shouldContain` "href=\"/en/about\""
      active `StrAssert.shouldContain` ("x-target.push=\"" <> contentTarget <> "\"")
    it "the rendered page does not prefetch its own route" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          let selfPrefetch = "@mouseenter=\"fetch($el.href" -- any link with prefetch
          -- The page must not contain a prefetching link whose href is its own URL.
          html `StrAssert.shouldNotContain`
            ("href=\"" <> routeUrl lang route <> "\" x-target.push=\"" <> contentTarget <> "\" " <> selfPrefetch)

  describe "Alpine seam — generated expressions (ADR-000 Vector B)" do
    -- These are the JavaScript strings that reach the browser. Nothing else in
    -- the stack can check them: a typo here compiles and fails at runtime.
    -- The expressions are generated in one place precisely so they can be
    -- pinned here.
    it "setFlag renders a boolean assignment" do
      renderExpr (setFlag MenuOpen false) `shouldEqual` "menuOpen = false"
      renderExpr (setFlag MenuOpen true) `shouldEqual` "menuOpen = true"
    it "toggleFlag inverts the same flag it assigns" do
      renderExpr (toggleFlag LangMenuOpen) `shouldEqual` "open = !open"
    it "flagName is injective — two flags cannot share an identifier" do
      -- A collision would silently wire two unrelated controls to one piece of
      -- state, which renders and tests fine until a user opens both.
      flagName MenuOpen `shouldNotEqual` flagName LangMenuOpen
    it "themeToggle persists the resolved class, not the pre-toggle state" do
      -- Reading classList back AFTER toggling is what keeps localStorage and
      -- the DOM in agreement; deriving it from the prior state would invert
      -- the theme on reload.
      renderExpr themeToggle `StrAssert.shouldContain` "classList.toggle('dark'); "
      renderExpr themeToggle `StrAssert.shouldContain` "classList.contains('dark') ? 'dark' : 'light'"
    it "setTheme generates explicit theme mutation expressions" do
      renderExpr (setTheme ThemeLight) `StrAssert.shouldContain` "classList.remove('dark')"
      renderExpr (setTheme ThemeDark) `StrAssert.shouldContain` "classList.add('dark')"
      renderExpr (setTheme ThemeSystem) `StrAssert.shouldContain` "prefers-color-scheme: dark"
    it "cycleTheme cycles between system, dark, and light" do
      renderExpr cycleTheme `StrAssert.shouldContain` "localStorage.setItem('theme', theme)"
      renderExpr cycleTheme `StrAssert.shouldContain` "classList.add('dark')"
      renderExpr cycleTheme `StrAssert.shouldContain` "classList.remove('dark')"
      renderExpr cycleTheme `StrAssert.shouldContain` "prefers-color-scheme: dark"
    it "aria-expanded is bound to the same flag x-show reads" do
      -- Drift between these renders fine but reports a collapsed menu to
      -- screen readers while it is visibly open.
      html <- renderStaticPage Home En
      html `StrAssert.shouldContain` "x-show=\"menuOpen\""
      html `StrAssert.shouldContain` ":aria-expanded=\"menuOpen.toString()\""

  describe "Alpine seam — typed constructors" do
    it "no raw Alpine attribute strings outside App.Alpine" do
      offenders <- findRawAlpineOutsideAlpine "src"
      offenders `shouldEqual` []

  describe "serviceCopy non-fallback coverage" do
    it "every service has a non-empty description in both languages" do
      for_ services \service ->
        for_ allLangs \lang -> do
          let copy = (dict lang).services.serviceCopy service.id
          copy.description `shouldNotEqual` ""
    it "every service has a non-empty title in both languages" do
      for_ services \service ->
        for_ allLangs \lang -> do
          let copy = (dict lang).services.serviceCopy service.id
          copy.title `shouldNotEqual` ""

  describe "no external script src" do
    -- PostList/PostDetail are data-backed (network fetch at render time)
    -- and are excluded — see `staticRoutes`. The two script tags must
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
          html `StrAssert.shouldContain` "if(localStorage.getItem('theme')==='dark'"
          html `StrAssert.shouldContain` "window.addEventListener(\"ajax:merged\",function(){var m=document.getElementById(\"content\");if(m&&m.dataset.pageTitle)document.title=m.dataset.pageTitle});"
          html `StrAssert.shouldContain` "var es=new EventSource('/dev/live-reload')"

  describe "pages flow through the layout shell" do
    it "every static page is a full document with a footer" do
      for_ staticRoutes \route ->
        for_ allLangs \lang -> do
          html <- renderStaticPage route lang
          html `StrAssert.shouldContain` "<!DOCTYPE html"
          html `StrAssert.shouldContain` "<footer"

    it "no raw/Raw words appear in src/" do
      -- Mirror of the Makefile's total source ban.
      offenders <- findRawInSrc "src"
      offenders `shouldEqual` []

    it "no banned functions in src/" do
      offenders <- findBannedInSrc "src"
      offenders `shouldEqual` []

    it "no foreign import outside allowlist" do
      offenders <- findForeignImportsOutsideAllowlist "src"
      offenders `shouldEqual` []

    it "no script elements outside App.Layout.Scripts and App.Layout.Page" do
      offenders <- findScriptsOutsideAllowlist "src"
      offenders `shouldEqual` []

  describe "feature isolation" do
    it "no feature module imports a sibling feature" do
      -- Features are self-contained (own Types/Service/Page/View): a
      -- feature may import its own submodules (e.g. Posts.Service →
      -- Posts.Types) but never another feature's modules. Cross-feature
      -- imports are hidden coupling — the shared data boundary lives in
      -- App.Data.Fetch instead.
      offenders <- findCrossFeatureImports "src/App/Features"
      offenders `shouldEqual` []

    describe "Bun.serve migration invariants" do
      it "spaLink includes @mouseenter fragment prefetch with $el (not this)" do
        let html = render (spaLink En Home [] [])
        -- Single quotes are escaped to &#x27; in the attribute value;
        -- the browser un-escapes them before Alpine executes the expression.
        html `StrAssert.shouldContain` "@mouseenter=\"fetch($el.href, {headers: {&#x27;x-alpine-request&#x27;: &#x27;true&#x27;}})\""
        html `StrAssert.shouldNotContain` "fetch(this.href)"

      it "renderPrefetch emits <link rel=\"prefetch\">" do
        let html = render (renderPrefetch En [ PostList ])
        html `StrAssert.shouldContain` "rel=\"prefetch\""
        html `StrAssert.shouldContain` "/en/posts"

      it "renderJsonLd returns Just for data-backed routes" do
        isJust (renderJsonLd "https://example.com" "test-nonce" En PostList) `shouldEqual` true
        isJust (renderJsonLd "https://example.com" "test-nonce" En Home) `shouldEqual` true
        isJust (renderJsonLd "https://example.com" "test-nonce" En About) `shouldEqual` false

      it "JSON-LD is XSS-safe" do
        -- The security invariant: < must be escaped as \u003c in JSON-LD
        -- content to prevent </script> injection. Test the actual rendered
        -- output, not just the escapeJson helper.
        escapeJson "<" `shouldEqual` "\\u003c"
        escapeJson "</script>" `shouldEqual` "\\u003c/script>"

      it "renderShellOpen produces valid HTML structure" do
        let html = renderShellOpen "https://example.com" "test-nonce-123" En Home
        html `StrAssert.shouldContain` "<!DOCTYPE html"
        html `StrAssert.shouldContain` "<main id=\"content\""
        html `StrAssert.shouldNotContain` "</main>"

      it "renderShellClose closes the document" do
        let html = renderShellClose "test-nonce-123" En Home
        html `StrAssert.shouldContain` "</main>"
        html `StrAssert.shouldContain` "</body></html>"

      it "escapeJson escapes in correct order" do
        -- Backslash must be escaped before quotes to avoid malformed JSON
        escapeJson "\\" `shouldEqual` "\\\\"
        escapeJson "\"" `shouldEqual` "\\\""

isJust :: forall a. Maybe a -> Boolean
isJust (Just _) = true
isJust Nothing = false

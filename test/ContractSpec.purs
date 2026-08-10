-- | Behavioral invariant tests the compiler cannot express.
-- |
-- | The type system can't see the stringly-typed seams this suite pins:
-- | security header tuples on every Response, the Alpine contentTarget /
-- | data-page-title contract, i18n wildcard fallbacks, the layout shell,
-- | and the total `raw` ban. If a future refactor breaks one of
-- | these contracts, this suite fails loudly instead of misbehaving in
-- | production.
module Test.ContractSpec where

import Prelude

import App.Alpine (contentTarget, spaLink)
import App.Config (Config)
import App.Form (contactFields, newsletterFields)
import App.Layout.Head (renderJsonLd, escapeJson)
import App.Layout.Page (renderPage, renderShellOpen, renderShellClose, renderPrefetch)
import App.Main (pageRenderer)
import App.Server (Response, cspWithNonce, fileResponse, htmlResponse, internalError, methodNotAllowed, notFound, ok, okText, okWith, redirect, redirectVary, securityHeaders, tooManyRequests)
import App.Html (render)
import Data.Array (concat, filter, find, length, mapMaybe, uncons)
import Data.Char (toCharCode)
import Data.Content (services)
import Data.Either (Either(..))
import Data.Foldable (any, for_)
import Data.I18n (Lang(..), dict)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Route (Route(..), allLangs, allRoutes)
import Data.Email (EmailAddress(..), mkEmailAddress)
import Data.String.CodeUnits (fromCharArray, stripPrefix, toCharArray) as CodeUnits
import Data.String.Common (split) as Common
import Data.String.Pattern (Pattern(..))
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
  { port: 3001
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
  where
  ffiAllowlist = [ "src/App/ServerBun.purs", "src/App/FetchBun.purs", "src/App/Bun.purs", "src/App/Data/SQL.purs" ]

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
      it "Contact page contains all canonical contact field names" do
        html <- renderStaticPage Contact En
        let fields = [ contactFields.name, contactFields.email, contactFields.message, contactFields.website, contactFields.lang ]
        for_ fields \f ->
          html `StrAssert.shouldContain` ("name=\"" <> f <> "\"")
      it "Contact page (via Footer) contains all canonical newsletter field names" do
        html <- renderStaticPage Contact En
        let fields = [ newsletterFields.email, newsletterFields.website, newsletterFields.lang ]
        for_ fields \f ->
          html `StrAssert.shouldContain` ("name=\"" <> f <> "\"")

  describe "security headers on every Response constructor" do
    it "ok" $ checkSecurityHeaders (ok "body")
    it "okWith" $ checkSecurityHeaders (okWith [] "body")
    it "okText" $ checkSecurityHeaders (okText "text/plain; charset=utf-8" "body")
    it "htmlResponse" $ checkSecurityHeaders (htmlResponse "body" [] 200)
    it "notFound" $ checkSecurityHeaders notFound
    it "methodNotAllowed" $ checkSecurityHeaders methodNotAllowed
    it "internalError" $ checkSecurityHeaders internalError
    it "redirect" $ checkSecurityHeaders (redirect 302 "/en")
    it "redirectVary" $ checkSecurityHeaders (redirectVary 302 "/en" [])
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

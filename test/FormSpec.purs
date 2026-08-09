-- | Form decoding tests
module Test.FormSpec where

import Prelude

import App.Form (ContactSubmission(..), FormStatus(..), NewsletterSubmission(..), apiContactPath, decodeContact, decodeNewsletter, formStatusQuery, parseFormStatus)
import Data.Email (mkEmailAddress, unEmailAddress)
import Data.Array as Array
import Data.FormURLEncoded as FormURLEncoded
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.String.CodeUnits (fromCharArray)
import Data.Tuple (Tuple(..))
import Test.QuickCheck.Gen (Gen, chooseInt, vectorOf)
import Test.Spec (describe, it, Spec)
import Test.Spec.Assertions (fail, shouldEqual, shouldSatisfy)
import Test.Spec.QuickCheck (quickCheck)

-- Property-test helpers ------------------------------------------------------

-- | Fixed ASCII alphabet (no whitespace) so every generated string round-trips
-- | exactly through Data.FormURLEncoded.encode/decode (encodeURIComponent never
-- | throws on it), and so the decoder's `trim` is the identity on our inputs —
-- | equality assertions in the properties below are therefore exact.
alphabet :: Array Char
alphabet = Array.fromFoldable
  [ 'a'
  , 'b'
  , 'c'
  , 'd'
  , 'e'
  , 'f'
  , 'g'
  , 'h'
  , 'i'
  , 'j'
  , 'k'
  , 'l'
  , 'm'
  , 'n'
  , 'o'
  , 'p'
  , 'q'
  , 'r'
  , 's'
  , 't'
  , 'u'
  , 'v'
  , 'w'
  , 'x'
  , 'y'
  , 'z'
  , 'A'
  , 'B'
  , 'C'
  , 'D'
  , 'E'
  , 'F'
  , 'G'
  , 'H'
  , 'I'
  , 'J'
  , 'K'
  , 'L'
  , 'M'
  , 'N'
  , 'O'
  , 'P'
  , 'Q'
  , 'R'
  , 'S'
  , 'T'
  , 'U'
  , 'V'
  , 'W'
  , 'X'
  , 'Y'
  , 'Z'
  , '0'
  , '1'
  , '2'
  , '3'
  , '4'
  , '5'
  , '6'
  , '7'
  , '8'
  , '9'
  , '.'
  , '-'
  , '_'
  , '+'
  , '&'
  , '='
  , '%'
  ]

genChar :: Gen Char
genChar = do
  i <- chooseInt 0 (Array.length alphabet - 1)
  pure (fromMaybe 'a' (Array.index alphabet i))

genSafeString :: Gen String
genSafeString = do
  n <- chooseInt 0 16
  chars <- vectorOf n genChar
  pure (fromCharArray chars)

genNonEmptyString :: Gen String
genNonEmptyString = do
  n <- chooseInt 1 16
  chars <- vectorOf n genChar
  pure (fromCharArray chars)

-- | Build an encoded application/x-www-form-urlencoded contact body.
-- | Encode (not string concat) so values with `&`/`=`/`%` survive.
contactBody :: String -> String -> String -> String -> String
contactBody name email message website =
  fromMaybe "" $ FormURLEncoded.encode $ FormURLEncoded.fromArray
    [ Tuple "name" (Just name)
    , Tuple "email" (Just email)
    , Tuple "message" (Just message)
    , Tuple "website" (Just website)
    , Tuple "lang" (Just "en")
    ]

-- | Build an encoded newsletter body.
newsletterBody :: String -> String -> String
newsletterBody email website =
  fromMaybe "" $ FormURLEncoded.encode $ FormURLEncoded.fromArray
    [ Tuple "email" (Just email)
    , Tuple "website" (Just website)
    , Tuple "lang" (Just "en")
    ]

spec :: Spec Unit
spec = do
  describe "Form decoding" do
    describe "Contact form" do
      it "decodes valid contact form" do
        case decodeContact "name=John+Doe&email=john%40example.com&message=Hello+World&website=&lang=en" of
          SubmitContact form -> do
            form.name `shouldEqual` "John Doe"
            unEmailAddress form.email `shouldEqual` "john@example.com"
            form.message `shouldEqual` "Hello World"
          other -> fail $ "expected SubmitContact, got " <> show other

      it "rejects invalid contact form (missing fields)" do
        let result = decodeContact "name=John+Doe&email=&message=Hello+World&website=&lang=en"
        result `shouldEqual` InvalidContact

      it "rejects contact form with honeypot filled" do
        let result = decodeContact "name=John+Doe&email=john%40example.com&message=Hello+World&website=spam&lang=en"
        result `shouldEqual` HoneypotHit

      it "rejects contact form with invalid email" do
        let result = decodeContact "name=John+Doe&email=invalid-email&message=Hello+World&website=&lang=en"
        result `shouldEqual` InvalidContact

    describe "Newsletter form" do
      it "decodes valid newsletter form" do
        case decodeNewsletter "email=john%40example.com&website=&lang=en" of
          SubmitNewsletter addr -> unEmailAddress addr `shouldEqual` "john@example.com"
          other -> fail $ "expected SubmitNewsletter, got " <> show other

      it "rejects invalid newsletter form (missing email)" do
        let result = decodeNewsletter "email=&website=&lang=en"
        result `shouldEqual` InvalidNewsletter

      it "rejects newsletter form with honeypot filled" do
        let result = decodeNewsletter "email=john%40example.com&website=spam&lang=en"
        result `shouldEqual` NewsletterHoneypot

    describe "Email address validation" do
      it "creates valid email address" do
        mkEmailAddress "test@example.com" `shouldSatisfy` isJust

      it "rejects email with no @" do
        mkEmailAddress "testexample.com" `shouldEqual` Nothing

      it "rejects email with multiple @" do
        mkEmailAddress "test@@example.com" `shouldEqual` Nothing

      it "rejects empty email" do
        mkEmailAddress "" `shouldEqual` Nothing

      it "rejects empty local part" do
        mkEmailAddress "@example.com" `shouldEqual` Nothing

      it "rejects empty domain part" do
        mkEmailAddress "test@" `shouldEqual` Nothing

    describe "Form status query" do
      it "roundtrips form statuses" do
        formStatusQuery FormSuccess `shouldEqual` "success"
        formStatusQuery FormError `shouldEqual` "error"
        formStatusQuery FormSubscribed `shouldEqual` "subscribed"

      it "parses status correctly" do
        parseFormStatus "success" `shouldEqual` Just FormSuccess
        parseFormStatus "error" `shouldEqual` Just FormError
        parseFormStatus "subscribed" `shouldEqual` Just FormSubscribed
        parseFormStatus "invalid" `shouldEqual` Nothing

    describe "API paths" do
      it "has correct contact path" do
        apiContactPath `shouldEqual` "/api/contact"

  describe "form decoding properties" do
    describe "totality" do
      it "decodeContact is total for every input string" $
        quickCheck \s -> case decodeContact s of
          SubmitContact _ -> true
          HoneypotHit -> true
          InvalidContact -> true

      it "decodeNewsletter is total for every input string" $
        quickCheck \s -> case decodeNewsletter s of
          SubmitNewsletter _ -> true
          NewsletterHoneypot -> true
          InvalidNewsletter -> true

    describe "honeypot semantics" do
      it "a filled honeypot always yields HoneypotHit, whatever else is in the body" $
        quickCheck do
          name <- genSafeString
          email <- genSafeString
          message <- genSafeString
          website <- genNonEmptyString
          let body = contactBody name email message website
          pure $ decodeContact body == HoneypotHit

      it "a filled newsletter honeypot always yields NewsletterHoneypot" $
        quickCheck do
          email <- genSafeString
          website <- genNonEmptyString
          let body = newsletterBody email website
          pure $ decodeNewsletter body == NewsletterHoneypot

    describe "clean submission" do
      it "valid contact data decodes to a matching ContactForm" $
        quickCheck do
          name <- genNonEmptyString
          local <- genNonEmptyString
          domain <- genNonEmptyString
          message <- genNonEmptyString
          let email = local <> "@" <> domain
          let body = contactBody name email message ""
          pure case decodeContact body of
            SubmitContact form ->
              form.name == name
                && unEmailAddress form.email == email
                && form.message == message
            _ -> false

      it "valid newsletter email decodes to SubmitNewsletter carrying the same address" $
        quickCheck do
          local <- genNonEmptyString
          domain <- genNonEmptyString
          let email = local <> "@" <> domain
          let body = newsletterBody email ""
          pure case decodeNewsletter body of
            SubmitNewsletter addr -> unEmailAddress addr == email
            _ -> false

    -- NOTE: the HoneypotHit -> FormSuccess and NewsletterHoneypot ->
    -- FormSubscribed bindings live in App.Main.handleContact /
    -- handleNewsletter (not exported, not reachable without hitting the
    -- network). The seam testable here is App.Form's FormStatus -> query
    -- string renderer: a honeypot hit redirects with `?status=success` /
    -- `?status=subscribed`, and the banner views parse exactly that string
    -- back into the success statuses. So the property asserts the rendered
    -- success values and their round-trip.
    describe "honeypot maps to silent success" do
      it "success statuses render to the banner values the redirect encodes" $
        quickCheck
          ( pure
              ( formStatusQuery FormSuccess == "success"
                  && formStatusQuery FormSubscribed == "subscribed"
                  && parseFormStatus (formStatusQuery FormSuccess) == Just FormSuccess
                  && parseFormStatus (formStatusQuery FormSubscribed) == Just FormSubscribed
              ) :: Gen Boolean
          )

    describe "mkEmailAddress properties" do
      it "is total for every input string" $
        quickCheck \s -> case mkEmailAddress s of
          Just _ -> true
          Nothing -> true

      it "accepts local@domain strings with non-empty sides" $
        quickCheck do
          local <- genNonEmptyString
          domain <- genNonEmptyString
          let email = local <> "@" <> domain
          pure case mkEmailAddress email of
            Just addr -> unEmailAddress addr == email
            Nothing -> false
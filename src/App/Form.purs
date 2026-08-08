-- | Form data structures and decoding for contact and newsletter forms.
-- |
-- | Single source of truth for the form contract between views and handlers:
-- | field names, honeypot fields, validation, status query params, API paths.
module App.Form
  ( ContactForm
  , ContactSubmission(..)
  , EmailAddress
  , FormStatus(..)
  , NewsletterSubmission(..)
  , apiContactPath
  , apiNewsletterPath
  , contactFields
  , decodeContact
  , decodeNewsletter
  , formStatusQuery
  , mkEmailAddress
  , newsletterFields
  , parseFormStatus
  , statusText
  , toMap
  , unEmailAddress
  ) where

import Prelude

import Data.Array as Array
import Data.FormURLEncoded (FormURLEncoded, decode)
import Data.FormURLEncoded as FormURLEncoded
import Data.I18n (Lang, dict)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.String (split, trim)
import Data.String.CodeUnits (length)
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))

-- ============================================================================
-- Form Status
-- ============================================================================

data FormStatus
  = FormSuccess
  | FormError
  | FormSubscribed

derive instance eqFormStatus :: Eq FormStatus

instance showFormStatus :: Show FormStatus where
  show FormSuccess = "success"
  show FormError = "error"
  show FormSubscribed = "subscribed"

formStatusQuery :: FormStatus -> String
formStatusQuery = case _ of
  FormSuccess -> "success"
  FormError -> "error"
  FormSubscribed -> "subscribed"

parseFormStatus :: String -> Maybe FormStatus
parseFormStatus = case _ of
  "success" -> Just FormSuccess
  "error" -> Just FormError
  "subscribed" -> Just FormSubscribed
  _ -> Nothing

-- | Translate form status to localized text
statusText :: Lang -> FormStatus -> String
statusText lang status =
  let
    d = dict lang
  in
    case status of
      FormSuccess -> d.common.formSuccess
      FormError -> d.common.formError
      FormSubscribed -> d.common.formSubscribed

-- ============================================================================
-- Email Address — smart constructor, the only way to mint one
-- ============================================================================

newtype EmailAddress = EmailAddress String

derive newtype instance eqEmailAddress :: Eq EmailAddress
derive newtype instance showEmailAddress :: Show EmailAddress

-- | Deliberately simple: trimmed, exactly one "@", non-empty local and domain.
mkEmailAddress :: String -> Maybe EmailAddress
mkEmailAddress input =
  let
    trimmed = trim input
  in
    case split (Pattern "@") trimmed of
      [ local, domain ]
        | length local > 0 && length domain > 0 -> Just (EmailAddress trimmed)
      _ -> Nothing

unEmailAddress :: EmailAddress -> String
unEmailAddress (EmailAddress s) = s

-- ============================================================================
-- Contact form
-- ============================================================================

type ContactForm =
  { name :: String
  , email :: EmailAddress
  , message :: String
  }

-- | Field names as used in HTML input `name` attributes. `website` is the
-- | honeypot — hidden from humans, filled by bots.
contactFields :: { name :: String, email :: String, message :: String, website :: String, lang :: String }
contactFields = { name: "name", email: "email", message: "message", website: "website", lang: "lang" }

-- | HoneypotHit must be treated as success by the caller (silent bot
-- | deflection) WITHOUT sending anything.
data ContactSubmission
  = SubmitContact ContactForm
  | HoneypotHit
  | InvalidContact

derive instance eqContactSubmission :: Eq ContactSubmission

instance showContactSubmission :: Show ContactSubmission where
  show = case _ of
    SubmitContact form -> "SubmitContact " <> form.name
    HoneypotHit -> "HoneypotHit"
    InvalidContact -> "InvalidContact"

decodeContact :: String -> ContactSubmission
decodeContact body = case decode body of
  Nothing -> InvalidContact
  Just encoded ->
    let
      m = toMap encoded
    in
      case Map.lookup contactFields.website m of
        Just website | trim website /= "" -> HoneypotHit
        _ ->
          case nonEmpty (Map.lookup contactFields.name m), nonEmpty (Map.lookup contactFields.email m), nonEmpty (Map.lookup contactFields.message m) of
            Just name, Just email, Just message ->
              case mkEmailAddress email of
                Just addr -> SubmitContact { name: name, email: addr, message: message }
                Nothing -> InvalidContact
            _, _, _ -> InvalidContact

-- ============================================================================
-- Newsletter form
-- ============================================================================

newsletterFields :: { email :: String, website :: String, lang :: String }
newsletterFields = { email: "email", website: "website", lang: "lang" }

data NewsletterSubmission
  = SubmitNewsletter EmailAddress
  | NewsletterHoneypot
  | InvalidNewsletter

derive instance eqNewsletterSubmission :: Eq NewsletterSubmission

instance showNewsletterSubmission :: Show NewsletterSubmission where
  show = case _ of
    SubmitNewsletter addr -> "SubmitNewsletter " <> unEmailAddress addr
    NewsletterHoneypot -> "NewsletterHoneypot"
    InvalidNewsletter -> "InvalidNewsletter"

decodeNewsletter :: String -> NewsletterSubmission
decodeNewsletter body = case decode body of
  Nothing -> InvalidNewsletter
  Just encoded ->
    let
      m = toMap encoded
    in
      case Map.lookup newsletterFields.website m of
        Just website | trim website /= "" -> NewsletterHoneypot
        _ ->
          case nonEmpty (Map.lookup newsletterFields.email m) of
            Nothing -> InvalidNewsletter
            Just email ->
              case mkEmailAddress email of
                Just addr -> SubmitNewsletter addr
                Nothing -> InvalidNewsletter

-- ============================================================================
-- API paths — the only place these strings live
-- ============================================================================

apiContactPath :: String
apiContactPath = "/api/contact"

apiNewsletterPath :: String
apiNewsletterPath = "/api/newsletter"

-- ============================================================================
-- Internal
-- ============================================================================

-- | form-urlencoded values are `Maybe String` (a bare `key` means Nothing);
-- | drop valueless keys.
toMap :: FormURLEncoded -> Map String String
toMap enc = Map.fromFoldable
  (Array.mapMaybe (\(Tuple k mv) -> Tuple k <$> mv) (FormURLEncoded.toArray enc))

nonEmpty :: Maybe String -> Maybe String
nonEmpty ms = case map trim ms of
  Just "" -> Nothing
  other -> other

-- | Type-safe internationalization (i18n).
-- |
-- | `Lang` is a sum type (exhaustive pattern matching).
-- | `Dictionary` is a nested record — the `en` instance defines the shape,
-- | `fr` must match it. The compiler enforces both languages have identical structure.
-- | When you add a key, both `en` and `fr` break at compile time.
module Data.I18n where

import Prelude
import Data.Content (ServiceId(..))
import Data.Maybe (Maybe(..))

-- ============================================================================
-- Language sum type
-- ============================================================================

data Lang = En | Fr

derive instance eqLang :: Eq Lang
derive instance ordLang :: Ord Lang

instance showLang :: Show Lang where
  show En = "en"
  show Fr = "fr"

-- | String tag for HTML lang attribute / URL prefix
langTag :: Lang -> String
langTag = case _ of
  En -> "en"
  Fr -> "fr"

-- | Parse a string tag into Lang
parseLang :: String -> Maybe Lang
parseLang "en" = Just En
parseLang "fr" = Just Fr
parseLang _ = Nothing

-- | Default language
defaultLang :: Lang
defaultLang = En

-- ============================================================================
-- Dictionary type — `en` defines the shape, `fr` must match
-- ============================================================================

-- | Localized text for one service card.
type ServiceCopy =
  { title :: String
  , description :: String
  }

type Dictionary =
  { nav ::
      { about :: String
      , contact :: String
      , posts :: String
      }
  , hero ::
      { headline :: String
      , body :: String
      , ctaLabel :: String
      }
  , services ::
      { sectionTitle :: String
      , bookButton :: String
      -- | Localized card copy by service id — pairs with Data.Content.services
      -- | metadata. Adding a service id there without a case here renders the
      -- | fallback below; keep both in sync when adding services.
      , serviceCopy :: ServiceId -> ServiceCopy
      }
  , cta ::
      { heading :: String
      , body :: String
      , ctaLabel :: String
      }
  , about ::
      { heading :: String
      , paragraphs :: Array String
      }
  , contact ::
      { title :: String
      , emailLabel :: String
      , messageLabel :: String
      , sendLabel :: String
      , socialLabel :: String
      , formName :: String
      }
  , posts ::
      { listTitle :: String
      , detailTitle :: String
      , readMore :: String
      , backToList :: String
      , loadingError :: String
      , notFound :: String
      , byAuthor :: String
      , unknownAuthor :: String
      }
  , footer ::
      { explore :: String
      , newsletter :: String
      , newsletterText :: String
      , newsletterPlaceholder :: String
      , newsletterButton :: String
      , copyright :: String
      }
  , common ::
      { siteTitle :: String
      , darkModeToggle :: String
      , newsletterEmailLabel :: String
      , formSuccess :: String
      , formError :: String
      , formSubscribed :: String
      , error404 :: String
      , error500 :: String
      , navAriaLabel :: String
      , menuLabel :: String
      , langToggleLabel :: String
      }
  }

-- ============================================================================
-- Translations
-- ============================================================================

en :: Dictionary
en =
  { nav:
      { about: "About"
      , contact: "Contact"
      , posts: "Posts"
      }
  , hero:
      { headline: "The Type-Safe Functional Web Framework for Bun"
      , body: "Build blazingly fast MPAs in PureScript with Bun runtime speed, Alpine.js micro-interactivity, and zero runtime exceptions."
      , ctaLabel: "About Pohjola"
      }
  , services:
      { sectionTitle: "Architectural Highlights"
      , bookButton: "GitHub"
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "PureScript Type Safety"
            , description: "Total pattern matching, no nulls, and an XSS-safe Html ADT that guarantees correctness at compile time."
            }
          ServiceId "service-2" ->
            { title: "Sub-Millisecond SSR on Bun"
            , description: "Native Bun server runtime delivering sub-millisecond route responses, lightweight streaming SSR, and instant dev server restarts."
            }
          ServiceId "service-3" ->
            { title: "Alpine.js Reactive Seams"
            , description: "Client-side micro-interactivity with typed Alpine constructors. Zero ad-hoc JavaScript scripts, seamless AJAX fragment swaps."
            }
          _ -> { title: "", description: "" }
      }
  , cta:
      { heading: "Start building with `make dev`"
      , body: "Clone the repository, run `make dev`, and experience full-stack functional web development with instant hot reload."
      , ctaLabel: "About Pohjola"
      }
  , about:
      { heading: "Architecture & Philosophy"
      , paragraphs:
          [ "Pohjola is an opinionated functional web framework built on PureScript, Bun, and Alpine.js. It combines the performance, SEO, and simplicity of Server-Side Rendered Multi-Page Applications (MPAs) with the fluid micro-interactivity of Single-Page Applications (SPAs) without complex client-side state bundles."
          , "Every layer is designed with strict invariants: total pattern matching, XSS prevention via an algebraic Html data type, byte-exact Content Security Policy (CSP) headers, honeypot form security, and typed bidirectional routing."
          ]
      }
  , contact:
      { title: "Feedback & Bug Reports"
      , emailLabel: "Email"
      , messageLabel: "Message"
      , sendLabel: "Send Message"
      , socialLabel: "Project Links"
      , formName: "Name"
      }
  , posts:
      { listTitle: "Engineering Notes & Architecture"
      , detailTitle: "Article"
      , readMore: "Read article"
      , backToList: "Back to articles"
      , loadingError: "Failed to load articles. Please check your connection."
      , notFound: "Article not found."
      , byAuthor: "By"
      , unknownAuthor: "Pohjola"
      }
  , footer:
      { explore: "Explore"
      , newsletter: "Updates"
      , newsletterText: "Subscribe for release notes and framework updates."
      , newsletterPlaceholder: "Email address"
      , newsletterButton: "Subscribe"
      , copyright: "© 2026 Pohjola Framework. Open source under MIT License."
      }
  , common:
      { siteTitle: "Pohjola"
      , darkModeToggle: "Toggle dark mode"
      , newsletterEmailLabel: "Email address"
      , formSuccess: "Thanks! Your message has been received."
      , formError: "Something went wrong — please try again."
      , formSubscribed: "You're subscribed to Pohjola updates!"
      , error404: "Page not found"
      , error500: "Something went wrong"
      , navAriaLabel: "Main navigation"
      , menuLabel: "Open menu"
      , langToggleLabel: "Switch language"
      }
  }

fr :: Dictionary
fr =
  { nav:
      { about: "À propos"
      , contact: "Contact"
      , posts: "Articles"
      }
  , hero:
      { headline: "Le framework web fonctionnel et typé pour Bun"
      , body: "Développez des applications web ultra-rapides en PureScript avec la puissance de Bun, la réactivité d'Alpine.js et zéro exception à l'exécution."
      , ctaLabel: "En savoir plus"
      }
  , services:
      { sectionTitle: "Points clés de l'architecture"
      , bookButton: "GitHub"
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "Sécurité de typage PureScript"
            , description: "Filtrage total par motif, aucun null, et un ADT Html typé sans faille XSS qui garantit la correction à la compilation."
            }
          ServiceId "service-2" ->
            { title: "SSR instantané sous Bun"
            , description: "Moteur d'exécution Bun natif offrant des temps de réponse sous la milliseconde, du streaming SSR et un rechargement instantané."
            }
          ServiceId "service-3" ->
            { title: "Interactivité Alpine.js typée"
            , description: "Micro-interactivité côté client avec des constructeurs Alpine typés. Zéro JavaScript ad-hoc et transitions AJAX fluides."
            }
          _ -> { title: "", description: "" }
      }
  , cta:
      { heading: "Commencez avec `make dev`"
      , body: "Clonez le dépôt, lancez `make dev` et découvrez le développement web full-stack fonctionnel avec rechargement instantané."
      , ctaLabel: "En savoir plus"
      }
  , about:
      { heading: "Architecture et philosophie"
      , paragraphs:
          [ "Pohjola est un framework web fonctionnel basé sur PureScript, Bun et Alpine.js. Il associe les performances et le SEO des applications multi-pages (MPA) avec la fluidité interactive des SPAs sans bundle JavaScript client."
          , "Chaque composant applique des garanties strictes : filtrage exhaustif par motif, prévention XSS par ADT Html typé, politique de sécurité CSP stricte, protection antispam honeypot et routage bidirectionnel typé."
          ]
      }
  , contact:
      { title: "Retours & signalement de bugs"
      , emailLabel: "E-mail"
      , messageLabel: "Message"
      , sendLabel: "Envoyer le message"
      , socialLabel: "Liens du projet"
      , formName: "Nom"
      }
  , posts:
      { listTitle: "Notes d'ingénierie et architecture"
      , detailTitle: "Article"
      , readMore: "Lire l'article"
      , backToList: "Retour aux articles"
      , loadingError: "Impossible de charger les articles. Veuillez vérifier votre connexion."
      , notFound: "Article introuvable."
      , byAuthor: "Par"
      , unknownAuthor: "Pohjola"
      }
  , footer:
      { explore: "Explorer"
      , newsletter: "Actualités"
      , newsletterText: "Abonnez-vous pour recevoir les notes de version et les actualités du framework."
      , newsletterPlaceholder: "Adresse e-mail"
      , newsletterButton: "S'inscrire"
      , copyright: "© 2026 Pohjola Framework. Open source sous licence MIT."
      }
  , common:
      { siteTitle: "Pohjola"
      , darkModeToggle: "Activer le mode sombre"
      , newsletterEmailLabel: "Adresse e-mail"
      , formSuccess: "Merci ! Votre message a bien été reçu."
      , formError: "Une erreur est survenue. Veuillez réessayer."
      , formSubscribed: "Vous êtes bien inscrit aux actualités Pohjola !"
      , error404: "Page introuvable"
      , error500: "Une erreur est survenue"
      , navAriaLabel: "Navigation principale"
      , menuLabel: "Ouvrir le menu"
      , langToggleLabel: "Changer de langue"
      }
  }

-- | Select the dictionary for a given language
dict :: Lang -> Dictionary
dict En = en
dict Fr = fr

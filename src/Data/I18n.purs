-- | Internationalization dictionary for Pohjola.
-- |
-- | Single source of truth for all localized user-facing text.
-- | `Dictionary` is a nested record — the `en` instance defines the shape,
-- | and the compiler enforces that `fr` has the exact same structure.
module Data.I18n
  ( Dictionary
  , Lang(..)
  , ServiceCopy
  , allLangs
  , defaultLang
  , dict
  , fr
  , langTag
  , parseLang
  ) where

import Prelude

import Data.Content (ServiceId(..))
import Data.Maybe (Maybe(..))

-- ============================================================================
-- Language type
-- ============================================================================

data Lang = En | Fr

derive instance eqLang :: Eq Lang
derive instance ordLang :: Ord Lang

instance showLang :: Show Lang where
  show En = "en"
  show Fr = "fr"

langTag :: Lang -> String
langTag En = "en"
langTag Fr = "fr"

parseLang :: String -> Maybe Lang
parseLang "en" = Just En
parseLang "fr" = Just Fr
parseLang _ = Nothing

allLangs :: Array Lang
allLangs = [ En, Fr ]

defaultLang :: Lang
defaultLang = En

-- ============================================================================
-- Dictionary type — `en` defines the shape, `fr` must match
-- ============================================================================

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
      , subtitle :: String
      , issuesTitle :: String
      , issuesText :: String
      , issuesButton :: String
      , discussionsTitle :: String
      , discussionsText :: String
      , discussionsButton :: String
      , sourceTitle :: String
      , sourceText :: String
      , sourceButton :: String
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
      , resources :: String
      , github :: String
      , issues :: String
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
      { heading: "Why Pohjola"
      , paragraphs:
          [ "Pohjola was born out of a desire to build web applications without the usual trade-offs: no bloated client bundles, no brittle string templates, and no surprise runtime exceptions in production. It pairs PureScript's uncompromising type system with the native speed of Bun and the lightweight interactivity of Alpine.js."
          , "The name comes from Finnish mythology and the atmosphere of Swallow the Sun's triple album Songs from the North. In Nordic lore, Pohjola is a harsh northern realm where things are forged to endure. That mindset shaped the framework: write explicit code, let the compiler enforce the contracts, and serve fast, semantic HTML to the browser."
          , "Instead of chasing framework churn or hydrating entire component trees in client memory, Pohjola keeps the architecture straightforward: pure functions transform typed data into HTML, routes are checked in both directions at compile time, and client interactivity is scoped to small, explicit Alpine expressions."
          ]
      }
  , contact:
      { title: "Community & Contributing"
      , subtitle: "Pohjola is open source under the MIT License. Report issues, join discussions, or inspect the codebase directly on GitHub."
      , issuesTitle: "Bug Reports & Issues"
      , issuesText: "Found a bug, edge case, or unexpected behavior? Open an issue on GitHub with reproduction steps."
      , issuesButton: "Open an Issue"
      , discussionsTitle: "Discussions & Q&A"
      , discussionsText: "Have architectural questions, design proposals, or want to discuss PureScript and Bun?"
      , discussionsButton: "Join Discussions"
      , sourceTitle: "Source Code & Invariants"
      , sourceText: "Explore the codebase, inspect verified safety invariants, or submit a pull request on GitHub."
      , sourceButton: "View Repository"
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
      { explore: "Navigation"
      , resources: "Resources"
      , github: "Source Code"
      , issues: "Bug Tracker"
      , copyright: "© 2026 Pohjola Framework. Open source under MIT License."
      }
  , common:
      { siteTitle: "Pohjola"
      , darkModeToggle: "Toggle dark mode"
      , newsletterEmailLabel: "Email address"
      , formSuccess: "Thanks! Your message has been received."
      , formError: "Something went wrong, please try again."
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
      { heading: "À propos de Pohjola"
      , paragraphs:
          [ "Pohjola est né d'une envie simple : concevoir des applications web sans compromis inutiles, loin des bundles JavaScript boursouflés, des templates non typés et des exceptions imprévues en production. Le framework combine la rigueur du système de types de PureScript, la rapidité d'exécution de Bun et la légèreté d'Alpine.js."
          , "Le nom s'inspire de la mythologie finlandaise et de l'atmosphère du triple album Songs from the North de Swallow the Sun. Dans les légendes nordiques, Pohjola est une terre rude où tout ce qui est forgé doit résister à l'épreuve du temps. C'est cette philosophie qui guide le projet : du code explicite, un compilateur qui valide chaque contrat et du HTML propre servi instantanément au navigateur."
          , "Plutôt que d'hydrater de lourdes architectures côté client, Pohjola privilégie la simplicité : des fonctions pures transforment les données typées en HTML, les routes sont vérifiées dans les deux sens à la compilation, et l'interactivité client reste confinée à des expressions Alpine ciblées."
          ]
      }
  , contact:
      { title: "Communauté & Contribution"
      , subtitle: "Pohjola est un projet open source sous licence MIT. Signalez des bugs, échangez ou explorez le code directement sur GitHub."
      , issuesTitle: "Bugs & Problèmes techniques"
      , issuesText: "Un problème, un bug ou un comportement inattendu ? Ouvrez une issue avec les étapes de reproduction."
      , issuesButton: "Ouvrir une issue"
      , discussionsTitle: "Discussions & Échanges"
      , discussionsText: "Des questions d'architecture, des propositions ou envie d'échanger autour de PureScript et Bun ?"
      , discussionsButton: "Rejoindre les discussions"
      , sourceTitle: "Code source & Invariants"
      , sourceText: "Explorez le dépôt, inspectez les garanties mécaniques ou proposez une contribution sur GitHub."
      , sourceButton: "Voir le dépôt"
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
      { explore: "Navigation"
      , resources: "Ressources"
      , github: "Code source"
      , issues: "Suivi des bugs"
      , copyright: "© 2026 Pohjola Framework. Open source sous licence MIT."
      }
  , common:
      { siteTitle: "Pohjola"
      , darkModeToggle: "Activer le mode sombre"
      , newsletterEmailLabel: "Adresse e-mail"
      , formSuccess: "Merci ! Votre message a bien été reçu."
      , formError: "Une erreur est survenue, veuillez réessayer."
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

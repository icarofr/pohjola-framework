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
  , seo ::
      { homeDescription :: String
      , aboutDescription :: String
      , contactDescription :: String
      , postsDescription :: String
      , postDetailDescription :: String
      }
  , common ::
      { siteTitle :: String
      , darkModeToggle :: String
      , themeLight :: String
      , themeDark :: String
      , themeSystem :: String
      , themeLabel :: String
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
      , body: "MPA simplicity with a seamless SPA experience. Built in PureScript with Bun runtime speed, Alpine.js micro-interactivity, and zero runtime exceptions."
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
      { heading: "About Pohjola"
      , paragraphs:
          [ "Pohjola takes its name from Swallow the Sun's Songs from the North, echoing the legendary realm of Finnish lore. In Finnish, pohja is both the bedrock beneath everything and the root of the North: not just a place, but a direction and a foundation. It evokes an unforgiving world of winter and myth where the master smith Ilmarinen forged the Sampo on an anvil of stone, where fragility is fatal and only deliberate, uncompromising craft can endure."
          , "We built Pohjola with that same ethos as an antidote to the fragility of modern web development: a true North for your applications. Rather than piling layers of transient JavaScript frameworks on top of one another, Pohjola rests on solid bedrock: PureScript proves correctness at compile time, Bun serves responses in sub-milliseconds, and the server renders clean, semantic HTML."
          , "Client-side interactivity remains light and transparent through small, typed Alpine.js expressions. You get the fluid responsiveness of a modern application without bloated runtimes, fragile state synchronization, or surprises when the cold winds blow in production."
          ]
      }
  , contact:
      { title: "Community & Contributing"
      , subtitle: "Pohjola is open source software. Report issues, join discussions, or inspect the codebase directly on GitHub."
      , issuesTitle: "Bug Reports & Issues"
      , issuesText: "Found a bug, edge case, or unexpected behaviour? Open an issue on GitHub with reproduction steps."
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
      , copyright: "© 2026 Pohjola Framework. Open source software."
      }
  , seo:
      { homeDescription: "The Type-Safe Functional Web Framework for Bun, PureScript, and Alpine.js"
      , aboutDescription: "Learn more about Pohjola."
      , contactDescription: "Get in touch with the Pohjola community."
      , postsDescription: "Read engineering notes and architectural highlights from Pohjola."
      , postDetailDescription: "An engineering note on Pohjola."
      }
  , common:
      { siteTitle: "Pohjola"
      , darkModeToggle: "Toggle dark mode"
      , themeLight: "Light"
      , themeDark: "Dark"
      , themeSystem: "System"
      , themeLabel: "Select theme"
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
      , body: "La simplicité d'une MPA avec la fluidité d'une SPA. Conçu en PureScript avec la vitesse de Bun, la réactivité d'Alpine.js et zéro exception à l'exécution."
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
          [ "Pohjola tire son nom de l'album Songs from the North de Swallow the Sun, hommage au royaume légendaire de la mythologie finlandaise. En finnois, pohja désigne à la fois le socle fondamental sur lequel tout repose et la racine du Nord : pas seulement un lieu, mais une direction et une fondation. Il évoque un monde d'hiver et de légendes où le maître forgeron Ilmarinen façonna le Sampo sur une enclume de pierre, où la fragilité ne pardonne pas et où seule une conception sans compromis résiste au temps."
          , "Nous avons conçu Pohjola selon cette même exigence pour répondre à la fragilité du web moderne : un cap clair pour vos applications. Au lieu d'empiler des couches d'abstractions éphémères, Pohjola s'établit sur un socle inébranlable : PureScript garantit la correction dès la compilation, Bun délivre chaque réponse en moins d'une milliseconde, et le serveur produit du HTML propre et sémantique."
          , "L'interactivité côté client reste légère et transparente grâce à de courtes expressions Alpine.js typées. Vous profitez de la fluidité d'une application moderne sans la lourdeur des SPA, sans synchronisation d'état complexe, et sans mauvaise surprise en production."
          ]
      }
  , contact:
      { title: "Communauté & Contribution"
      , subtitle: "Pohjola est un projet open source. Signalez des bugs, échangez ou explorez le code directement sur GitHub."
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
      , copyright: "© 2026 Pohjola Framework. Logiciel open source."
      }
  , seo:
      { homeDescription: "Le framework web fonctionnel et typé pour Bun, PureScript et Alpine.js"
      , aboutDescription: "En savoir plus sur Pohjola."
      , contactDescription: "Rejoindre la communauté et contribuer à Pohjola."
      , postsDescription: "Lire les notes d'ingénierie et l'architecture de Pohjola."
      , postDetailDescription: "Un article d'ingénierie sur Pohjola."
      }
  , common:
      { siteTitle: "Pohjola"
      , darkModeToggle: "Activer le mode sombre"
      , themeLight: "Clair"
      , themeDark: "Sombre"
      , themeSystem: "Système"
      , themeLabel: "Sélectionner le thème"
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

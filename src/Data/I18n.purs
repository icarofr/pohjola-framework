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
      , legal :: String
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
  , legal ::
      { title :: String
      , subtitle :: String
      , lastUpdated :: String
      , sections :: Array { number :: String, heading :: String, paragraphs :: Array String }
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
      , legal: "Legal"
      , posts: "Posts"
      }
  , hero:
      { headline: "Your headline here"
      , body: "Your compelling value proposition goes here. Explain what you do and why it matters."
      , ctaLabel: "Learn more"
      }
  , services:
      { sectionTitle: "Our services"
      , bookButton: "Get started"
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "Service One"
            , description: "Description of your first service. What does it include? What problem does it solve?"
            }
          ServiceId "service-2" ->
            { title: "Service Two"
            , description: "Description of your second service. Highlight the key benefit."
            }
          ServiceId "service-3" ->
            { title: "Service Three"
            , description: "Description of your third service. Keep it concise and clear."
            }
          _ -> { title: "", description: "" }
      }
  , cta:
      { heading: "Get started today"
      , body: "Ready to take the next step? It only takes a few clicks."
      , ctaLabel: "Contact us"
      }
  , about:
      { heading: "About us"
      , paragraphs:
          [ "Tell your story here. Who are you? What experience do you bring? Why should people trust you?"
          , "Add a second paragraph with more detail about your background, credentials, or approach."
          ]
      }
  , contact:
      { title: "Contact"
      , emailLabel: "Email"
      , messageLabel: "Message"
      , sendLabel: "Send"
      , socialLabel: "Follow us"
      , formName: "Name"
      }
  , posts:
      { listTitle: "Posts"
      , detailTitle: "Post"
      , readMore: "Read more"
      , backToList: "Back to posts"
      , loadingError: "Failed to load posts. Please try again later."
      , notFound: "Post not found."
      , byAuthor: "By"
      , unknownAuthor: "User"
      }
  , footer:
      { explore: "Explore"
      , newsletter: "Newsletter"
      , newsletterText: "Subscribe to receive news and updates."
      , newsletterPlaceholder: "Email address"
      , newsletterButton: "Subscribe"
      , copyright: "© 2026 Your Site. All rights reserved."
      }
  , legal:
      { title: "Legal Notice"
      , subtitle: "Terms of Service"
      , lastUpdated: "January 2026"
      , sections:
          [ { number: "1"
            , heading: "Purpose"
            , paragraphs:
                [ "These Terms of Service define the terms under which the service is offered."
                ]
            }
          , { number: "2"
            , heading: "Provider Information"
            , paragraphs:
                [ "Replace with your legal entity information."
                ]
            }
          , { number: "3"
            , heading: "Applicable Law"
            , paragraphs:
                [ "These terms are governed by applicable law. Replace with your jurisdiction."
                ]
            }
          ]
      }
  , common:
      { siteTitle: "PS Alpine Starter"
      , darkModeToggle: "Toggle dark mode"
      , newsletterEmailLabel: "Email address"
      , formSuccess: "Thanks! Your message has been sent."
      , formError: "Something went wrong — please try again."
      , formSubscribed: "You're subscribed!"
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
      , legal: "Mentions légales"
      , posts: "Articles"
      }
  , hero:
      { headline: "Votre titre ici"
      , body: "Votre proposition de valeur va ici. Expliquez ce que vous faites et pourquoi c'est important."
      , ctaLabel: "En savoir plus"
      }
  , services:
      { sectionTitle: "Nos services"
      , bookButton: "Commencer"
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "Service Un"
            , description: "Description de votre premier service. Qu'est-ce qu'il inclut ? Quel problème résout-il ?"
            }
          ServiceId "service-2" ->
            { title: "Service Deux"
            , description: "Description de votre deuxième service. Soulignez l'avantage principal."
            }
          ServiceId "service-3" ->
            { title: "Service Trois"
            , description: "Description de votre troisième service. Restez concis et clair."
            }
          _ -> { title: "", description: "" }
      }
  , cta:
      { heading: "Commencez aujourd'hui"
      , body: "Prêt à faire le prochain pas ? Cela ne prend que quelques clics."
      , ctaLabel: "Nous contacter"
      }
  , about:
      { heading: "À propos"
      , paragraphs:
          [ "Racontez votre histoire ici. Qui êtes-vous ? Quelle expérience apportez-vous ?"
          , "Ajoutez un deuxième paragraphe avec plus de détails sur votre parcours."
          ]
      }
  , contact:
      { title: "Contact"
      , emailLabel: "E-mail"
      , messageLabel: "Message"
      , sendLabel: "Envoyer"
      , socialLabel: "Suivez-nous"
      , formName: "Nom"
      }
  , posts:
      { listTitle: "Articles"
      , detailTitle: "Article"
      , readMore: "Lire la suite"
      , backToList: "Retour aux articles"
      , loadingError: "Impossible de charger les articles. Veuillez réessayer plus tard."
      , notFound: "Article introuvable."
      , byAuthor: "Par"
      , unknownAuthor: "Utilisateur"
      }
  , footer:
      { explore: "Explorer"
      , newsletter: "Newsletter"
      , newsletterText: "Inscrivez-vous pour recevoir les actualités."
      , newsletterPlaceholder: "Adresse e-mail"
      , newsletterButton: "S'inscrire"
      , copyright: "© 2026 Votre Site. Tous droits réservés."
      }
  , legal:
      { title: "Mentions légales"
      , subtitle: "Conditions générales"
      , lastUpdated: "Janvier 2026"
      , sections:
          [ { number: "1"
            , heading: "Objet"
            , paragraphs:
                [ "Les présentes conditions définissent les modalités d'utilisation du service."
                ]
            }
          , { number: "2"
            , heading: "Informations sur le prestataire"
            , paragraphs:
                [ "Remplacez par les informations légales de votre entité."
                ]
            }
          , { number: "3"
            , heading: "Droit applicable"
            , paragraphs:
                [ "Les présentes conditions sont régies par le droit applicable. Remplacez par votre juridiction."
                ]
            }
          ]
      }
  , common:
      { siteTitle: "PS Alpine Starter"
      , darkModeToggle: "Activer le mode sombre"
      , newsletterEmailLabel: "Adresse e-mail"
      , formSuccess: "Merci ! Votre message a bien été envoyé."
      , formError: "Une erreur est survenue. Veuillez réessayer."
      , formSubscribed: "Vous êtes bien inscrit !"
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

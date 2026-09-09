-- | Internationalization dictionary for Pohjola.
-- |
-- | Single source of truth for all localized user-facing text.
-- | `Dictionary` is a nested record — the `en` instance defines the shape,
-- | and the compiler enforces that `fr` and `pt` have the exact same structure.
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

data Lang = En | Fr | Pt

derive instance eqLang :: Eq Lang
derive instance ordLang :: Ord Lang

instance showLang :: Show Lang where
  show En = "en"
  show Fr = "fr"
  show Pt = "pt"

langTag :: Lang -> String
langTag En = "en"
langTag Fr = "fr"
langTag Pt = "pt"

parseLang :: String -> Maybe Lang
parseLang "en" = Just En
parseLang "fr" = Just Fr
parseLang "pt" = Just Pt
parseLang _ = Nothing

allLangs :: Array Lang
allLangs = [ En, Fr, Pt ]

defaultLang :: Lang
defaultLang = En

-- ============================================================================
-- Dictionary type — `en` defines the shape, `fr` and `pt` must match
-- ============================================================================
--
-- Rebuilding for the clean-sheet rebuild (see .scratch/clean-sheet-homepage/):
-- `nav`/`hero`/`services`/`cta`/`seo.homeDescription` are back for `Home`
-- (ticket 02, placeholder copy — ticket 03 writes the real hero/pillar/CTA
-- text). `about`/`contact`/`posts`/`fixtures` stay gone; the old `about`/
-- `guarantees`/`docs` sections return with tickets 04/05/06.

type ServiceCopy =
  { title :: String
  , description :: String
  , actionLabel :: String
  }

type Dictionary =
  { nav ::
      { home :: String
      , about :: String
      , guarantees :: String
      , docs :: String
      }
  , hero ::
      { eyebrow :: String
      , headline :: String
      , body :: String
      , ctaLabel :: String
      , secondaryLabel :: String
      }
  , services ::
      { sectionEyebrow :: String
      , sectionHeadline :: String
      , sectionIntro :: String
      -- | Localized card copy by service id — pairs with Data.Content.services
      , serviceCopy :: ServiceId -> ServiceCopy
      }
  , cta ::
      { heading :: String
      , body :: String
      , ctaLabel :: String
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

      , guaranteesDescription :: String

      , docsDescription :: String
      }
  , about ::
      { heading :: String
      , body :: String
      }
  , guarantees ::
      { heading :: String
      , body :: String
      }
  , docs ::
      { heading :: String
      , body :: String
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
      , closeSidebarLabel :: String
      , closeMenuLabel :: String
      , closeLabel :: String
      , authorLabel :: String
      , publishedLabel :: String
      }
  }

-- ============================================================================
-- Translations
-- ============================================================================

en :: Dictionary
en =
  { nav:
      { home: "Home"
      , about: "About"
      , guarantees: "Guarantees"
      , docs: "Docs"
      }
  , hero:
      { eyebrow: "Draft copy"
      , headline: "Pohjola homepage — draft placeholder"
      , body: "Placeholder hero copy scaffolded by ticket 02; ticket 03 writes the real pitch."
      , ctaLabel: "Placeholder CTA"
      , secondaryLabel: "Placeholder link"
      }
  , services:
      { sectionEyebrow: "Draft"
      , sectionHeadline: "Placeholder pillars"
      , sectionIntro: "Placeholder — ticket 03 writes the real pillar copy."
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "Placeholder pillar one"
            , description: "Placeholder description — ticket 03 replaces this."
            , actionLabel: "Learn more"
            }
          ServiceId "service-2" ->
            { title: "Placeholder pillar two"
            , description: "Placeholder description — ticket 03 replaces this."
            , actionLabel: "Learn more"
            }
          ServiceId "service-3" ->
            { title: "Placeholder pillar three"
            , description: "Placeholder description — ticket 03 replaces this."
            , actionLabel: "Learn more"
            }
          _ -> { title: "", description: "", actionLabel: "" }
      }
  , cta:
      { heading: "Placeholder CTA heading"
      , body: "Placeholder CTA body — ticket 03 replaces this."
      , ctaLabel: "Placeholder CTA"
      }
  , seo:
      { homeDescription: "The Type-Safe Functional Web Framework for Bun, PureScript, and Alpine.js"
      , aboutDescription: "SEO for About."

      , guaranteesDescription: "SEO for Guarantees."

      , docsDescription: "SEO for Docs."
      }
  , footer:
      { explore: "Navigation"
      , resources: "Resources"
      , github: "Source Code"
      , issues: "Bug Tracker"
      , copyright: "© 2026 Pohjola Framework. Open source software."
      }
  , about:
      { heading: "About"
      , body: "Explore our About."
      }
  , guarantees:
      { heading: "Guarantees"
      , body: "Explore our Guarantees."
      }
  , docs:
      { heading: "Docs"
      , body: "Explore our Docs."
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
      , closeSidebarLabel: "Close sidebar"
      , closeMenuLabel: "Close menu"
      , closeLabel: "Close"
      , authorLabel: "Author"
      , publishedLabel: "Published"
      }
  }

fr :: Dictionary
fr =
  { nav:
      { home: "Accueil"
      , about: "About"
      , guarantees: "Guarantees"
      , docs: "Docs"
      }
  , hero:
      { eyebrow: "Texte provisoire"
      , headline: "Page d'accueil Pohjola — brouillon"
      , body: "Texte de remplacement généré par le ticket 02 ; le ticket 03 écrira le vrai texte."
      , ctaLabel: "CTA provisoire"
      , secondaryLabel: "Lien provisoire"
      }
  , services:
      { sectionEyebrow: "Brouillon"
      , sectionHeadline: "Piliers provisoires"
      , sectionIntro: "Texte provisoire — le ticket 03 écrira le vrai texte."
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "Pilier provisoire un"
            , description: "Description provisoire — remplacée par le ticket 03."
            , actionLabel: "En savoir plus"
            }
          ServiceId "service-2" ->
            { title: "Pilier provisoire deux"
            , description: "Description provisoire — remplacée par le ticket 03."
            , actionLabel: "En savoir plus"
            }
          ServiceId "service-3" ->
            { title: "Pilier provisoire trois"
            , description: "Description provisoire — remplacée par le ticket 03."
            , actionLabel: "En savoir plus"
            }
          _ -> { title: "", description: "", actionLabel: "" }
      }
  , cta:
      { heading: "Titre CTA provisoire"
      , body: "Texte CTA provisoire — remplacé par le ticket 03."
      , ctaLabel: "CTA provisoire"
      }
  , seo:
      { homeDescription: "Le framework web fonctionnel et typé pour Bun, PureScript et Alpine.js"
      , aboutDescription: "SEO for About."

      , guaranteesDescription: "SEO for Guarantees."

      , docsDescription: "SEO for Docs."
      }
  , footer:
      { explore: "Navigation"
      , resources: "Ressources"
      , github: "Code source"
      , issues: "Suivi des bugs"
      , copyright: "© 2026 Pohjola Framework. Logiciel open source."
      }
  , about:
      { heading: "About"
      , body: "Description de About."
      }
  , guarantees:
      { heading: "Guarantees"
      , body: "Description de Guarantees."
      }
  , docs:
      { heading: "Docs"
      , body: "Description de Docs."
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
      , closeSidebarLabel: "Fermer le panneau latéral"
      , closeMenuLabel: "Fermer le menu"
      , closeLabel: "Fermer"
      , authorLabel: "Auteur"
      , publishedLabel: "Publié"
      }
  }

pt :: Dictionary
pt =
  { nav:
      { home: "Início"
      , about: "About"
      , guarantees: "Guarantees"
      , docs: "Docs"
      }
  , hero:
      { eyebrow: "Texto provisório"
      , headline: "Página inicial do Pohjola — rascunho"
      , body: "Texto provisório gerado pelo ticket 02; o ticket 03 escreverá o texto real."
      , ctaLabel: "CTA provisório"
      , secondaryLabel: "Link provisório"
      }
  , services:
      { sectionEyebrow: "Rascunho"
      , sectionHeadline: "Pilares provisórios"
      , sectionIntro: "Texto provisório — o ticket 03 escreverá o texto real."
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "Pilar provisório um"
            , description: "Descrição provisória — substituída pelo ticket 03."
            , actionLabel: "Saiba mais"
            }
          ServiceId "service-2" ->
            { title: "Pilar provisório dois"
            , description: "Descrição provisória — substituída pelo ticket 03."
            , actionLabel: "Saiba mais"
            }
          ServiceId "service-3" ->
            { title: "Pilar provisório três"
            , description: "Descrição provisória — substituída pelo ticket 03."
            , actionLabel: "Saiba mais"
            }
          _ -> { title: "", description: "", actionLabel: "" }
      }
  , cta:
      { heading: "Título CTA provisório"
      , body: "Texto CTA provisório — substituído pelo ticket 03."
      , ctaLabel: "CTA provisório"
      }
  , seo:
      { homeDescription: "O framework web funcional e tipado para Bun, PureScript e Alpine.js"
      , aboutDescription: "SEO for About."

      , guaranteesDescription: "SEO for Guarantees."

      , docsDescription: "SEO for Docs."
      }
  , footer:
      { explore: "Navegação"
      , resources: "Recursos"
      , github: "Código-fonte"
      , issues: "Rastreador de bugs"
      , copyright: "© 2026 Pohjola Framework. Software open source."
      }
  , about:
      { heading: "About"
      , body: "Explore o About."
      }
  , guarantees:
      { heading: "Guarantees"
      , body: "Explore o Guarantees."
      }
  , docs:
      { heading: "Docs"
      , body: "Explore o Docs."
      }
  , common:
      { siteTitle: "Pohjola"
      , darkModeToggle: "Alternar modo escuro"
      , themeLight: "Claro"
      , themeDark: "Escuro"
      , themeSystem: "Sistema"
      , themeLabel: "Selecionar tema"
      , newsletterEmailLabel: "Endereço de e-mail"
      , formSuccess: "Obrigado! A sua mensagem foi recebida."
      , formError: "Algo correu mal, tente novamente."
      , formSubscribed: "Está subscrito às atualizações do Pohjola!"
      , error404: "Página não encontrada"
      , error500: "Algo correu mal"
      , navAriaLabel: "Navegação principal"
      , menuLabel: "Abrir menu"
      , langToggleLabel: "Mudar de idioma"
      , closeSidebarLabel: "Fechar barra lateral"
      , closeMenuLabel: "Fechar menu"
      , closeLabel: "Fechar"
      , authorLabel: "Autor"
      , publishedLabel: "Publicado"
      }
  }

-- | Select the dictionary for a given language
dict :: Lang -> Dictionary
dict En = en
dict Fr = fr
dict Pt = pt

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
      , docs: "Docs (soon)"
      }
  , hero:
      { eyebrow: "PureScript on Bun"
      , headline: "A framework built to make AI-written code safer to ship"
      , body: "Pohjola pairs an agent-friendly page generator with a compiler that refuses common mistakes. Pages feel instant — Alpine prefetches on hover and swaps fragments in place — while PureScript proves every route is handled, every string is escaped, and a crash never reaches your users."
      , ctaLabel: "See the guarantees"
      , secondaryLabel: "View the repository"
      }
  , services:
      { sectionEyebrow: "Why Pohjola"
      , sectionHeadline: "Built to catch mistakes before they ship"
      , sectionIntro: "Three deliberate choices, each backed by a mechanical check — not a style guide."
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "PureScript Type Safety"
            , description: "Total pattern matching, no null, an XSS-safe Html type. A route your code doesn't handle is a compile error, not a 3am page."
            , actionLabel: "See the guarantees"
            }
          ServiceId "service-2" ->
            { title: "Bun-Native Speed"
            , description: "No Node cold start, no module-resolution tax — Bun serves and rebuilds natively. The dev server restarts before you've moved your cursor back to the browser."
            , actionLabel: "Learn more"
            }
          ServiceId "service-3" ->
            { title: "Typed Alpine Seams"
            , description: "Client interactivity comes from closed PureScript types, not hand-rolled scripts. There's no way to slip an unchecked onclick string past the policy gate."
            , actionLabel: "Learn more"
            }
          _ -> { title: "", description: "", actionLabel: "" }
      }
  , cta:
      { heading: "Start with `make dev`"
      , body: "Clone the repository, run `make dev`, and you have a working page in under a minute — the same pipeline that built this site."
      , ctaLabel: "View the repository"
      }
  , seo:
      { homeDescription: "Pohjola — a type-safe PureScript framework on Bun, built to make AI-assisted code safer to ship."
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
      , docs: "Docs (soon)"
      }
  , hero:
      { eyebrow: "PureScript sur Bun"
      , headline: "Un framework conçu pour sécuriser le code écrit par l'IA"
      , body: "Pohjola associe un générateur de pages pensé pour les agents à un compilateur qui refuse les erreurs courantes. Les pages semblent instantanées — Alpine précharge au survol et remplace les fragments sur place — tandis que PureScript garantit que chaque route est gérée, chaque chaîne est échappée, et qu'aucun plantage n'atteint vos utilisateurs."
      , ctaLabel: "Voir les garanties"
      , secondaryLabel: "Voir le dépôt"
      }
  , services:
      { sectionEyebrow: "Pourquoi Pohjola"
      , sectionHeadline: "Conçu pour intercepter les erreurs avant leur mise en production"
      , sectionIntro: "Trois choix délibérés, chacun vérifié mécaniquement — pas un simple guide de style."
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "Sécurité de typage PureScript"
            , description: "Filtrage total par motif, aucun null, un type Html protégé contre le XSS. Une route non gérée par votre code est une erreur de compilation, pas un incident à 3h du matin."
            , actionLabel: "Voir les garanties"
            }
          ServiceId "service-2" ->
            { title: "Vitesse native Bun"
            , description: "Pas de démarrage à froid façon Node, pas de coût de résolution de modules — Bun sert et recompile nativement. Le serveur de développement redémarre avant que vous n'ayez reposé le curseur sur le navigateur."
            , actionLabel: "En savoir plus"
            }
          ServiceId "service-3" ->
            { title: "Coutures Alpine typées"
            , description: "L'interactivité côté client provient de types PureScript fermés, jamais de scripts écrits à la main. Impossible de glisser un onclick brut au-delà du contrôle de politique."
            , actionLabel: "En savoir plus"
            }
          _ -> { title: "", description: "", actionLabel: "" }
      }
  , cta:
      { heading: "Commencez avec `make dev`"
      , body: "Clonez le dépôt, lancez `make dev`, et vous avez une page fonctionnelle en moins d'une minute — le même pipeline qui a construit ce site."
      , ctaLabel: "Voir le dépôt"
      }
  , seo:
      { homeDescription: "Pohjola — un framework PureScript typé sur Bun, conçu pour sécuriser le code assisté par IA."
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
      , docs: "Docs (soon)"
      }
  , hero:
      { eyebrow: "PureScript no Bun"
      , headline: "Um framework feito para tornar o código escrito por IA mais seguro"
      , body: "O Pohjola combina um gerador de páginas pensado para agentes com um compilador que recusa erros comuns. As páginas parecem instantâneas — o Alpine pré-carrega ao passar o rato e substitui fragmentos no lugar — enquanto o PureScript garante que cada rota é tratada, cada string é escapada, e nenhuma falha chega aos seus utilizadores."
      , ctaLabel: "Ver as garantias"
      , secondaryLabel: "Ver o repositório"
      }
  , services:
      { sectionEyebrow: "Porquê o Pohjola"
      , sectionHeadline: "Feito para apanhar erros antes de irem para produção"
      , sectionIntro: "Três escolhas deliberadas, cada uma verificada mecanicamente — não um simples guia de estilo."
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "Segurança de tipos PureScript"
            , description: "Correspondência de padrões total, sem nulls, um tipo Html protegido contra XSS. Uma rota que o seu código não trata é um erro de compilação, não um incidente às 3 da manhã."
            , actionLabel: "Ver as garantias"
            }
          ServiceId "service-2" ->
            { title: "Velocidade nativa do Bun"
            , description: "Sem arranque a frio à maneira do Node, sem custo de resolução de módulos — o Bun serve e recompila nativamente. O servidor de desenvolvimento reinicia antes de voltar a colocar o cursor no navegador."
            , actionLabel: "Saiba mais"
            }
          ServiceId "service-3" ->
            { title: "Costuras Alpine tipadas"
            , description: "A interatividade do lado do cliente vem de tipos PureScript fechados, nunca de scripts escritos à mão. Não há forma de passar um onclick em bruto pelo portão de política."
            , actionLabel: "Saiba mais"
            }
          _ -> { title: "", description: "", actionLabel: "" }
      }
  , cta:
      { heading: "Comece com `make dev`"
      , body: "Clone o repositório, execute `make dev`, e tem uma página a funcionar em menos de um minuto — o mesmo pipeline que construiu este site."
      , ctaLabel: "Ver o repositório"
      }
  , seo:
      { homeDescription: "Pohjola — um framework PureScript tipado sobre o Bun, feito para tornar o código assistido por IA mais seguro."
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

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
      , subtitle :: String
      , mission ::
          { heading :: String
          , lead :: String
          , body :: String
          }
      , values ::
          { heading :: String
          , intro :: String
          , items ::
              { one :: { title :: String, description :: String }
              , two :: { title :: String, description :: String }
              , three :: { title :: String, description :: String }
              , four :: { title :: String, description :: String }
              , five :: { title :: String, description :: String }
              , six :: { title :: String, description :: String }
              }
          }
      }
  , guarantees ::
      { heading :: String
      , subtitle :: String
      , lead :: String
      , cards ::
          { one :: { title :: String, description :: String, buttonLabel :: String }
          , two :: { title :: String, description :: String, buttonLabel :: String }
          , three :: { title :: String, description :: String, buttonLabel :: String }
          }
      }
  , docs ::
      { heading :: String
      , subtitle :: String
      , lead :: String
      , itemsHeading :: String
      , itemsIntro :: String
      , items :: Array { title :: String, description :: String }
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
      , aboutDescription: "Why Pohjola exists and the six engineering principles behind it."

      , guaranteesDescription: "What Pohjola mechanically guarantees, and how to verify each claim yourself."

      , docsDescription: "Documentation is coming - see what's planned and what already exists in the repository."
      }
  , footer:
      { explore: "Navigation"
      , resources: "Resources"
      , github: "Source Code"
      , issues: "Bug Tracker"
      , copyright: "© 2026 Pohjola Framework. Open source software."
      }
  , about:
      { heading: "About Pohjola"
      , subtitle: "A type-safe framework built specifically for a world where code also gets written by agents."
      , mission:
          { heading: "Why Pohjola exists"
          , lead: "Most frameworks assume a careful human is writing every line. Pohjola assumes an agent might be — and builds the guardrails accordingly."
          , body: "Pohjola started as the foundation for the author's own apps, then went public because the same problem shows up everywhere: AI-assisted code ships fast and reviews thin. Instead of counting on careful prompts, Pohjola pushes the safety net into the compiler and the policy gate — a mistake either doesn't compile, or fails a mechanical check before it ships."
          }
      , values:
          { heading: "Our principles"
          , intro: "Six choices that shape every decision in this codebase."
          , items:
              { one: { title: "The compiler over the reviewer", description: "A missing case, an unescaped string, a forbidden import — caught by `spago build` and `make gate`, not by whoever happens to review the PR." }
              , two: { title: "Built for agents", description: "The page generator, the typed Alpine constructors, and the policy gate exist so an agent gets a narrow, checkable path instead of a blank file and good intentions." }
              , three: { title: "Honest about scope", description: "GUARANTEES.md states exactly what's proven and what isn't. A claim with no check next to it doesn't ship." }
              , four: { title: "Bun-native, not Node-adjacent", description: "No compatibility shims — Bun's own primitives (Bun.serve, Bun.sql, Bun.password) are the FFI boundary itself, tamed and explicitly allowlisted." }
              , five: { title: "Small surface, edges filed off", description: "Four pages, one Html type, one Alpine module. Depth comes from what each piece proves, not from how many pieces exist." }
              , six: { title: "Built in the open", description: "ADRs, conventions, and eval prompts are part of the repository, not tribal knowledge — anyone, human or agent, can reconstruct why a decision was made." }
              }
          }
      }
  , guarantees:
      { heading: "Guarantees"
      , subtitle: "Every claim on this page is backed by a check you can run yourself."
      , lead: "If it compiles and CI is green, production doesn't crash. That's not a claim of zero runtime errors in the absolute — this stack still touches effects, FFI boundaries, and a JavaScript runtime — but every clause below is backed by a real, run-it-yourself check, not a promise."
      , cards:
          { one: { title: "No unsafe code paths", description: "Force-unwrapping a Maybe, casting past the type system, and any unapproved FFI module all fail the build in src/. Every handler failure is a typed value too — a missed case is a compile error, not a runtime surprise.", buttonLabel: "View the policy gate" }
          , two: { title: "Locked-down browser surface", description: "The Html type has no general-purpose unescaped-HTML constructor, security headers and a nonce-based CSP with no unsafe-inline are asserted on every response, and browser interactivity comes from closed PureScript types — no hand-written onclick strings.", buttonLabel: "View the source" }
          , three: { title: "Proven on every push", description: "Form decoding never throws for any input, a filled honeypot always means a silent success, and make gate, make test, Venom, and Playwright all run in GitHub Actions on every push — not a claim checked once.", buttonLabel: "View the CI config" }
          }
      }
  , docs:
      { heading: "Docs"
      , subtitle: "An honest placeholder while the real documentation gets written."
      , lead: "There's no documentation site yet — this page exists so that's a visible, honest gap instead of a silent one. Until then, the source is the documentation: the ADRs and convention docs live in the repository itself, and the eval prompts double as worked examples."
      , itemsHeading: "What's coming first"
      , itemsIntro: "Six sections already scoped, in the order they'll be written."
      , items:
          [ { title: "Getting started", description: "Clone the repository, run `make dev`, and have a working page in minutes — written up as a real walkthrough, not just this paragraph." }
          , { title: "Page architectures", description: "When a page should be static versus data-backed, and what the template layer actually gives you." }
          , { title: "Conventions", description: "Alpine contracts, forms, and the chrome checklist — the rules `make gate` already enforces, explained instead of just checked." }
          , { title: "Architecture decisions", description: "The ADR index: why Bun instead of Node, why the Html type has no escape hatch, why the CSP is pinned instead of configurable." }
          , { title: "Guarantees, explained", description: "The reasoning behind each guarantee on the previous page, and how to verify it yourself." }
          , { title: "Contributing", description: "How to open an issue, propose an ADR, and where the test suite expects new coverage." }
          ]
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
      , about: "À propos"
      , guarantees: "Garanties"
      , docs: "Docs (bientôt)"
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
      , aboutDescription: "Pourquoi Pohjola existe et les six principes d'ingénierie qui le guident."

      , guaranteesDescription: "Ce que Pohjola garantit mécaniquement, et comment vérifier chaque affirmation vous-même."

      , docsDescription: "La documentation arrive - découvrez ce qui est prévu et ce qui existe déjà dans le dépôt."
      }
  , footer:
      { explore: "Navigation"
      , resources: "Ressources"
      , github: "Code source"
      , issues: "Suivi des bugs"
      , copyright: "© 2026 Pohjola Framework. Logiciel open source."
      }
  , about:
      { heading: "À propos de Pohjola"
      , subtitle: "Un framework typé conçu spécifiquement pour un monde où le code est aussi écrit par des agents."
      , mission:
          { heading: "Pourquoi Pohjola existe"
          , lead: "La plupart des frameworks supposent qu'un humain attentif écrit chaque ligne. Pohjola suppose qu'il pourrait s'agir d'un agent — et construit les garde-fous en conséquence."
          , body: "Pohjola a d'abord servi de socle aux applications de son auteur, puis est devenu public parce que le même problème se retrouve partout : le code assisté par IA avance vite et les relectures s'amincissent. Plutôt que de compter sur des prompts soignés, Pohjola déplace le filet de sécurité vers le compilateur et le contrôle de politique — une erreur ne compile pas, ou échoue à un contrôle mécanique avant d'être livrée."
          }
      , values:
          { heading: "Nos principes"
          , intro: "Six choix qui façonnent chaque décision de ce dépôt."
          , items:
              { one: { title: "Le compilateur plutôt que le relecteur", description: "Un cas manquant, une chaîne non échappée, un import interdit — intercepté par `spago build` et `make gate`, pas par qui relit la PR ce jour-là." }
              , two: { title: "Pensé pour les agents", description: "Le générateur de pages, les constructeurs Alpine typés et le contrôle de politique existent pour offrir à un agent un chemin étroit et vérifiable plutôt qu'un fichier vide et de bonnes intentions." }
              , three: { title: "Honnête sur son périmètre", description: "GUARANTEES.md indique précisément ce qui est prouvé et ce qui ne l'est pas. Une promesse sans contrôle en face n'est pas livrée." }
              , four: { title: "Natif Bun, pas adjacent à Node", description: "Aucune couche de compatibilité — les primitives de Bun (Bun.serve, Bun.sql, Bun.password) sont la frontière FFI elle-même, maîtrisée et listée explicitement." }
              , five: { title: "Surface réduite, arêtes limées", description: "Quatre pages, un seul type Html, un seul module Alpine. La profondeur vient de ce que chaque pièce prouve, pas de leur nombre." }
              , six: { title: "Construit à ciel ouvert", description: "ADRs, conventions et prompts d'évaluation font partie du dépôt, pas d'un savoir informel — chacun, humain ou agent, peut reconstituer pourquoi une décision a été prise." }
              }
          }
      }
  , guarantees:
      { heading: "Garanties"
      , subtitle: "Chaque affirmation de cette page repose sur un contrôle que vous pouvez lancer vous-même."
      , lead: "Si ça compile et que la CI est verte, la production ne plante pas. Ce n'est pas une promesse de zéro erreur d'exécution dans l'absolu — cette stack touche encore des effets, des frontières FFI et un runtime JavaScript — mais chaque clause ci-dessous s'appuie sur un contrôle réel, que vous pouvez lancer vous-même, pas sur une simple promesse."
      , cards:
          { one: { title: "Aucun chemin de code non sûr", description: "Forcer le déballage d'un Maybe, un cast qui contourne le système de types, ou tout module FFI non approuvé font échouer la compilation dans src/. Chaque échec de handler est aussi une valeur typée — un cas oublié est une erreur de compilation, pas une surprise à l'exécution.", buttonLabel: "Voir le contrôle de politique" }
          , two: { title: "Surface navigateur verrouillée", description: "Le type Html n'a aucun constructeur HTML non échappé à usage général, les en-têtes de sécurité et une CSP à nonce sans unsafe-inline sont vérifiés sur chaque réponse, et l'interactivité du navigateur vient de types PureScript fermés — aucun onclick écrit à la main.", buttonLabel: "Voir le code source" }
          , three: { title: "Prouvé à chaque push", description: "Le décodage des formulaires ne lève jamais d'exception, un honeypot rempli signifie toujours un succès silencieux, et make gate, make test, Venom et Playwright tournent tous dans GitHub Actions à chaque push — pas une promesse vérifiée une fois.", buttonLabel: "Voir la config CI" }
          }
      }
  , docs:
      { heading: "Documentation"
      , subtitle: "Un espace réservé honnête, le temps d'écrire la vraie documentation."
      , lead: "Il n'existe pas encore de site de documentation — cette page rend cette lacune visible et honnête plutôt que silencieuse. En attendant, la source fait office de documentation : les ADRs et les docs de convention vivent dans le dépôt lui-même, et les prompts d'évaluation servent d'exemples concrets."
      , itemsHeading: "Ce qui arrive en premier"
      , itemsIntro: "Six sections déjà identifiées, dans l'ordre où elles seront écrites."
      , items:
          [ { title: "Premiers pas", description: "Clonez le dépôt, lancez `make dev`, et obtenez une page fonctionnelle en quelques minutes — présenté comme un vrai guide, pas juste ce paragraphe." }
          , { title: "Architectures de page", description: "Quand choisir une page statique plutôt qu'une page adossée à des données, et ce que la couche de gabarits offre réellement." }
          , { title: "Conventions", description: "Contrats Alpine, formulaires, checklist de l'habillage — les règles que `make gate` impose déjà, expliquées plutôt que simplement vérifiées." }
          , { title: "Décisions d'architecture", description: "L'index des ADRs : pourquoi Bun plutôt que Node, pourquoi le type Html n'a pas d'échappatoire, pourquoi la CSP est figée plutôt que configurable." }
          , { title: "Les garanties expliquées", description: "Le raisonnement derrière chaque garantie de la page précédente, et comment le vérifier vous-même." }
          , { title: "Contribuer", description: "Comment ouvrir une issue, proposer un ADR, et où la suite de tests attend une nouvelle couverture." }
          ]
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
      , about: "Sobre"
      , guarantees: "Garantias"
      , docs: "Docs (em breve)"
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
      , aboutDescription: "Porque é que o Pohjola existe e os seis princípios de engenharia por trás dele."

      , guaranteesDescription: "O que o Pohjola garante mecanicamente, e como verificar cada afirmação você mesmo."

      , docsDescription: "A documentação está a chegar - veja o que está planeado e o que já existe no repositório."
      }
  , footer:
      { explore: "Navegação"
      , resources: "Recursos"
      , github: "Código-fonte"
      , issues: "Rastreador de bugs"
      , copyright: "© 2026 Pohjola Framework. Software open source."
      }
  , about:
      { heading: "Sobre o Pohjola"
      , subtitle: "Um framework tipado feito especificamente para um mundo onde o código também é escrito por agentes."
      , mission:
          { heading: "Porque é que o Pohjola existe"
          , lead: "A maioria dos frameworks assume que um humano atento escreve cada linha. O Pohjola assume que pode ser um agente — e constrói as proteções em conformidade."
          , body: "O Pohjola começou como a base das próprias aplicações do autor, e tornou-se público porque o mesmo problema aparece em todo o lado: código assistido por IA é escrito depressa e as revisões ficam mais superficiais. Em vez de confiar em prompts cuidadosos, o Pohjola move a rede de segurança para o compilador e para o portão de política — um erro não compila, ou falha numa verificação mecânica antes de ser publicado."
          }
      , values:
          { heading: "Os nossos princípios"
          , intro: "Seis escolhas que moldam cada decisão neste repositório."
          , items:
              { one: { title: "O compilador em vez do revisor", description: "Um caso em falta, uma string não escapada, um import proibido — apanhados pelo `spago build` e `make gate`, não por quem revê o PR nesse dia." }
              , two: { title: "Pensado para agentes", description: "O gerador de páginas, os construtores Alpine tipados e o portão de política existem para dar a um agente um caminho estreito e verificável, em vez de um ficheiro vazio e boas intenções." }
              , three: { title: "Honesto quanto ao alcance", description: "O GUARANTEES.md diz exatamente o que está provado e o que não está. Uma promessa sem uma verificação ao lado não é publicada." }
              , four: { title: "Nativo do Bun, não um substituto do Node", description: "Sem camadas de compatibilidade — as primitivas do Bun (Bun.serve, Bun.sql, Bun.password) são a própria fronteira FFI, controlada e listada explicitamente." }
              , five: { title: "Superfície pequena, arestas limadas", description: "Quatro páginas, um único tipo Html, um único módulo Alpine. A profundidade vem do que cada peça prova, não de quantas existem." }
              , six: { title: "Construído a céu aberto", description: "ADRs, convenções e prompts de avaliação fazem parte do repositório, não são conhecimento informal — qualquer pessoa, humana ou agente, pode reconstruir porque é que uma decisão foi tomada." }
              }
          }
      }
  , guarantees:
      { heading: "Garantias"
      , subtitle: "Cada afirmação nesta página assenta numa verificação que pode correr você mesmo."
      , lead: "Se compila e o CI está verde, a produção não cai. Não é uma promessa de zero erros de execução no absoluto — esta stack ainda toca em efeitos, fronteiras FFI e um runtime JavaScript — mas cada cláusula abaixo assenta numa verificação real, que pode correr você mesmo, não numa simples promessa."
      , cards:
          { one: { title: "Nenhum caminho de código inseguro", description: "Forçar o desembrulho de um Maybe, um cast que contorna o sistema de tipos, ou qualquer módulo FFI não aprovado fazem falhar a compilação em src/. Cada falha de handler também é um valor tipado — um caso esquecido é um erro de compilação, não uma surpresa em produção.", buttonLabel: "Ver o portão de política" }
          , two: { title: "Superfície do navegador fechada", description: "O tipo Html não tem nenhum construtor HTML não escapado de uso geral, cabeçalhos de segurança e uma CSP com nonce sem unsafe-inline são verificados em cada resposta, e a interatividade do navegador vem de tipos PureScript fechados — nenhum onclick escrito à mão.", buttonLabel: "Ver o código-fonte" }
          , three: { title: "Provado a cada push", description: "A descodificação de formulários nunca gera exceções, um honeypot preenchido significa sempre sucesso silencioso, e make gate, make test, Venom e Playwright correm todos no GitHub Actions a cada push — não é uma promessa verificada uma vez.", buttonLabel: "Ver a config de CI" }
          }
      }
  , docs:
      { heading: "Documentação"
      , subtitle: "Um espaço reservado honesto, enquanto a documentação real é escrita."
      , lead: "Ainda não existe um site de documentação — esta página torna essa lacuna visível e honesta, em vez de silenciosa. Até lá, o código-fonte serve de documentação: os ADRs e os documentos de convenção vivem no próprio repositório, e os prompts de avaliação funcionam como exemplos práticos."
      , itemsHeading: "O que vem primeiro"
      , itemsIntro: "Seis secções já identificadas, pela ordem em que serão escritas."
      , items:
          [ { title: "Primeiros passos", description: "Clone o repositório, execute `make dev`, e tenha uma página a funcionar em minutos — escrito como um guia real, não apenas este parágrafo." }
          , { title: "Arquiteturas de página", description: "Quando usar uma página estática em vez de uma apoiada em dados, e o que a camada de modelos realmente oferece." }
          , { title: "Convenções", description: "Contratos Alpine, formulários, a checklist do chrome — as regras que o `make gate` já impõe, explicadas em vez de apenas verificadas." }
          , { title: "Decisões de arquitetura", description: "O índice de ADRs: porque Bun em vez de Node, porque o tipo Html não tem escape, porque a CSP é fixa em vez de configurável." }
          , { title: "As garantias, explicadas", description: "O raciocínio por trás de cada garantia da página anterior, e como a verificar você mesmo." }
          , { title: "Contribuir", description: "Como abrir uma issue, propor um ADR, e onde a suite de testes espera nova cobertura." }
          ]
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

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
-- Dictionary type — `en` defines the shape, `fr` must match
-- ============================================================================

type ServiceCopy =
  { title :: String
  , description :: String
  , actionLabel :: String
  }

type Dictionary =
  { nav ::
      { home :: String
      , about :: String
      , contact :: String
      , posts :: String
      , fixtures :: String
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
  , contact ::
      { title :: String
      , subtitle :: String
      , issuesTag :: String
      , issuesTitle :: String
      , issuesText :: String
      , issuesButton :: String
      , discussionsTag :: String
      , discussionsTitle :: String
      , discussionsText :: String
      , discussionsButton :: String
      , sourceTag :: String
      , sourceTitle :: String
      , sourceText :: String
      , sourceButton :: String
      }
  , posts ::
      { listTitle :: String
      , listSubtitle :: String
      , detailTitle :: String
      , articleTagPrefix :: String
      , readMore :: String
      , backToList :: String
      , loadingError :: String
      , notFound :: String
      , byAuthor :: String
      , authorRole :: String
      , unknownAuthor :: String
      }
  , fixtures ::
      { listTitle :: String
      , subtitle :: String
      , homeLabel :: String
      , awayLabel :: String
      , homeVenue :: String
      , awayVenue :: String
      , sourceLabel :: String
      , vsLabel :: String
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
      , fixturesDescription :: String
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
      { home: "Home"
      , about: "About"
      , contact: "Contact"
      , posts: "Posts"
      , fixtures: "Fixtures"
      }
  , hero:
      { eyebrow: "PureScript · Bun · Alpine.js"
      , headline: "The Type-Safe Functional Web Framework for Bun"
      , body: "MPA simplicity with a seamless SPA experience. Built in PureScript with Bun runtime speed, Alpine.js micro-interactivity, and zero runtime exceptions."
      , ctaLabel: "About Pohjola"
      , secondaryLabel: "Browse notes"
      }
  , services:
      { sectionEyebrow: "Foundations"
      , sectionHeadline: "Architectural Highlights"
      , sectionIntro: "PureScript, Bun, and Alpine.js — composed deliberately and verified mechanically."
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "PureScript Type Safety"
            , description: "Total pattern matching, no nulls, and an XSS-safe Html ADT that guarantees correctness at compile time."
            , actionLabel: "See the stack"
            }
          ServiceId "service-2" ->
            { title: "Sub-Millisecond SSR on Bun"
            , description: "Native Bun server runtime delivering sub-millisecond route responses, lightweight streaming SSR, and instant dev server restarts."
            , actionLabel: "Read the notes"
            }
          ServiceId "service-3" ->
            { title: "Alpine.js Reactive Seams"
            , description: "Client-side micro-interactivity with typed Alpine constructors. Zero ad-hoc JavaScript scripts, seamless AJAX fragment swaps."
            , actionLabel: "Contribute"
            }
          _ -> { title: "", description: "", actionLabel: "" }
      }
  , cta:
      { heading: "Start building with `make dev`"
      , body: "Clone the repository, run `make dev`, and experience full-stack functional web development with instant hot reload."
      , ctaLabel: "View the repository"
      }
  , about:
      { heading: "About Pohjola"
      , subtitle: "A type-safe functional web framework for Bun — bedrock-first, agent-verified."
      , mission:
          { heading: "Our mission"
          , lead: "Pohjola takes its name from Swallow the Sun's Songs from the North — Finnish lore where pohja is both bedrock and the direction North. We built the framework on that ethos: deliberate craft that survives production."
          , body: "Rather than piling transient JavaScript frameworks on top of one another, Pohjola rests on solid bedrock. PureScript proves correctness at compile time, Bun serves responses in sub-milliseconds, and the server renders clean, semantic HTML with light Alpine.js seams."
          }
      , values:
          { heading: "Our values"
          , intro: "These principles guide every architectural decision in the framework."
          , items:
              { one: { title: "Bedrock over fashion", description: "Prefer proven foundations — typed HTML, explicit errors, and server-first rendering — over the framework churn of the week." }
              , two: { title: "Open by default", description: "Safety invariants, policy gates, and conventions are documented and testable so contributors can reason about the system." }
              , three: { title: "Always learning", description: "ADRs, evals, and convention docs encode what we learned so the next change starts from shared context." }
              , four: { title: "Supportive seams", description: "Alpine interactivity stays typed and minimal — enough UX polish without smuggling a client runtime through the back door." }
              , five: { title: "Take responsibility", description: "Errors are values, CSP is pinned, and caches are conservative because production surprises are our problem, not the user's." }
              , six: { title: "Enjoy restraint", description: "A small surface area you can hold in your head beats a maximal toolkit you have to fight on every feature." }
              }
          }
      }
  , contact:
      { title: "Community & Contributing"
      , subtitle: "Report issues, join discussions, or inspect the codebase directly on GitHub."
      , issuesTag: "Issues"
      , issuesTitle: "Bug Reports & Issues"
      , issuesText: "Found a bug, edge case, or unexpected behaviour? Open an issue on GitHub with reproduction steps."
      , issuesButton: "Open an Issue"
      , discussionsTag: "Community"
      , discussionsTitle: "Discussions & Q&A"
      , discussionsText: "Have architectural questions, design proposals, or want to discuss PureScript and Bun?"
      , discussionsButton: "Join Discussions"
      , sourceTag: "Source"
      , sourceTitle: "Source Code & Invariants"
      , sourceText: "Explore the codebase, inspect verified safety invariants, or submit a pull request on GitHub."
      , sourceButton: "View Repository"
      }
  , posts:
      { listTitle: "Engineering Notes"
      , listSubtitle: "Stack deep-dives, conventions, and guarantees."
      , detailTitle: "Article"
      , articleTagPrefix: "Article #"
      , readMore: "Read article"
      , backToList: "Back to articles"
      , loadingError: "Failed to load articles. Please check your connection."
      , notFound: "Article not found."
      , byAuthor: "By"
      , authorRole: "Engineering"
      , unknownAuthor: "Pohjola"
      }
  , fixtures:
      { listTitle: "Fixtures"
      , subtitle: "Upcoming Tottenham Hotspur matches — schedule sourced from OneFootball."
      , homeLabel: "Home"
      , awayLabel: "Away"
      , homeVenue: "Tottenham Hotspur Stadium"
      , awayVenue: "Away fixture"
      , sourceLabel: "THFC"
      , vsLabel: "vs"
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
      , fixturesDescription: "Upcoming Tottenham Hotspur fixtures for the 2026 season."
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
      { home: "Accueil"
      , about: "À propos"
      , contact: "Contact"
      , posts: "Articles"
      , fixtures: "Calendrier"
      }
  , hero:
      { eyebrow: "PureScript · Bun · Alpine.js"
      , headline: "Le framework web fonctionnel et typé pour Bun"
      , body: "La simplicité d'une MPA avec la fluidité d'une SPA. Conçu en PureScript avec la vitesse de Bun, la réactivité d'Alpine.js et zéro exception à l'exécution."
      , ctaLabel: "En savoir plus"
      , secondaryLabel: "Lire les articles"
      }
  , services:
      { sectionEyebrow: "Fondations"
      , sectionHeadline: "Points clés de l'architecture"
      , sectionIntro: "PureScript, Bun et Alpine.js — composés avec intention et vérifiés mécaniquement."
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "Sécurité de typage PureScript"
            , description: "Filtrage total par motif, aucun null, et un ADT Html typé sans faille XSS qui garantit la correction à la compilation."
            , actionLabel: "Voir l'approche"
            }
          ServiceId "service-2" ->
            { title: "SSR instantané sous Bun"
            , description: "Moteur d'exécution Bun natif offrant des temps de réponse sous la milliseconde, du streaming SSR et un rechargement instantané."
            , actionLabel: "Lire les notes"
            }
          ServiceId "service-3" ->
            { title: "Interactivité Alpine.js typée"
            , description: "Micro-interactivité côté client avec des constructeurs Alpine typés. Zéro JavaScript ad-hoc et transitions AJAX fluides."
            , actionLabel: "Contribuer"
            }
          _ -> { title: "", description: "", actionLabel: "" }
      }
  , cta:
      { heading: "Commencez avec `make dev`"
      , body: "Clonez le dépôt, lancez `make dev` et découvrez le développement web full-stack fonctionnel avec rechargement instantané."
      , ctaLabel: "Voir le dépôt"
      }
  , about:
      { heading: "À propos de Pohjola"
      , subtitle: "Un framework web fonctionnel et typé pour Bun — fondations solides, vérifié par les agents."
      , mission:
          { heading: "Notre mission"
          , lead: "Pohjola tire son nom de Songs from the North de Swallow the Sun — la mythologie finnoise où pohja est à la fois le socle et la direction du Nord. Nous avons bâti le framework sur cette exigence : un artisanat délibéré qui tient en production."
          , body: "Plutôt que d'empiler des frameworks JavaScript éphémères, Pohjola repose sur un socle solide. PureScript garantit la correction à la compilation, Bun répond en moins d'une milliseconde, et le serveur produit du HTML sémantique avec des coutures Alpine.js légères."
          }
      , values:
          { heading: "Nos valeurs"
          , intro: "Ces principes guident chaque décision architecturale du framework."
          , items:
              { one: { title: "Le socle avant la mode", description: "HTML typé, erreurs explicites et rendu serveur d'abord — plutôt que la mode du moment." }
              , two: { title: "Ouvert par défaut", description: "Invariants, politiques et conventions documentés et testables pour que chacun puisse raisonner sur le système." }
              , three: { title: "Apprendre en continu", description: "ADRs, evals et docs de convention encodent ce que nous avons appris pour la prochaine évolution." }
              , four: { title: "Coutures bienveillantes", description: "L'interactivité Alpine reste typée et minimale — assez de polish sans runtime client déguisé." }
              , five: { title: "Assumer la responsabilité", description: "Les erreurs sont des valeurs, la CSP est figée, et les caches restent prudents : la production nous regarde." }
              , six: { title: "La retenue comme force", description: "Une surface maîtrisable vaut mieux qu'une boîte à outils maximale à combattre à chaque feature." }
              }
          }
      }
  , contact:
      { title: "Communauté & Contribution"
      , subtitle: "Signalez des bugs, échangez ou explorez le code directement sur GitHub."
      , issuesTag: "Issues"
      , issuesTitle: "Bugs & Problèmes techniques"
      , issuesText: "Un problème, un bug ou un comportement inattendu ? Ouvrez une issue avec les étapes de reproduction."
      , issuesButton: "Ouvrir une issue"
      , discussionsTag: "Communauté"
      , discussionsTitle: "Discussions & Échanges"
      , discussionsText: "Des questions d'architecture, des propositions ou envie d'échanger autour de PureScript et Bun ?"
      , discussionsButton: "Rejoindre les discussions"
      , sourceTag: "Code"
      , sourceTitle: "Code source & Invariants"
      , sourceText: "Explorez le dépôt, inspectez les garanties mécaniques ou proposez une contribution sur GitHub."
      , sourceButton: "Voir le dépôt"
      }
  , posts:
      { listTitle: "Notes d'ingénierie"
      , listSubtitle: "Stack, conventions et garanties."
      , detailTitle: "Article"
      , articleTagPrefix: "Article n°"
      , readMore: "Lire l'article"
      , backToList: "Retour aux articles"
      , loadingError: "Impossible de charger les articles. Veuillez vérifier votre connexion."
      , notFound: "Article introuvable."
      , byAuthor: "Par"
      , authorRole: "Ingénierie"
      , unknownAuthor: "Pohjola"
      }
  , fixtures:
      { listTitle: "Calendrier"
      , subtitle: "Prochains matchs de Tottenham Hotspur — calendrier issu de OneFootball."
      , homeLabel: "Domicile"
      , awayLabel: "Extérieur"
      , homeVenue: "Tottenham Hotspur Stadium"
      , awayVenue: "Match à l'extérieur"
      , sourceLabel: "THFC"
      , vsLabel: "vs"
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
      , fixturesDescription: "Prochains matchs de Tottenham Hotspur pour la saison 2026."
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

pt :: Dictionary
pt =
  { nav:
      { home: "Início"
      , about: "Sobre"
      , contact: "Contato"
      , posts: "Artigos"
      , fixtures: "Calendário"
      }
  , hero:
      { eyebrow: "PureScript · Bun · Alpine.js"
      , headline: "O framework web funcional e tipado para Bun"
      , body: "A simplicidade de uma MPA com a fluidez de uma SPA. Construído em PureScript com a velocidade do Bun, a micro-interatividade do Alpine.js e zero exceções em tempo de execução."
      , ctaLabel: "Sobre o Pohjola"
      , secondaryLabel: "Ver notas"
      }
  , services:
      { sectionEyebrow: "Fundações"
      , sectionHeadline: "Destaques da arquitetura"
      , sectionIntro: "PureScript, Bun e Alpine.js — compostos de propósito e verificados mecanicamente."
      , serviceCopy: \sid -> case sid of
          ServiceId "service-1" ->
            { title: "Segurança de tipos PureScript"
            , description: "Correspondência de padrões total, sem nulls, e um ADT Html tipado que garante correção na compilação."
            , actionLabel: "Ver a stack"
            }
          ServiceId "service-2" ->
            { title: "SSR em submilissegundos no Bun"
            , description: "Runtime Bun nativo com respostas de rota em submilissegundos, SSR em streaming leve e reinícios instantâneos do servidor de desenvolvimento."
            , actionLabel: "Ler as notas"
            }
          ServiceId "service-3" ->
            { title: "Costuras reativas Alpine.js"
            , description: "Micro-interatividade no cliente com construtores Alpine tipados. Zero JavaScript ad hoc e trocas AJAX fluidas."
            , actionLabel: "Contribuir"
            }
          _ -> { title: "", description: "", actionLabel: "" }
      }
  , cta:
      { heading: "Comece com `make dev`"
      , body: "Clone o repositório, execute `make dev` e experimente desenvolvimento web full-stack funcional com recarregamento instantâneo."
      , ctaLabel: "Ver o repositório"
      }
  , about:
      { heading: "Sobre o Pohjola"
      , subtitle: "Um framework web funcional e tipado para Bun — base sólida, verificado por agentes."
      , mission:
          { heading: "A nossa missão"
          , lead: "Pohjola toma o nome de Songs from the North de Swallow the Sun — o folclore finlandês onde pohja é ao mesmo tempo a base e a direção Norte. Construímos o framework sobre esse ethos: artesanato deliberado que aguenta produção."
          , body: "Em vez de empilhar frameworks JavaScript transitórios, o Pohjola assenta numa base sólida. PureScript prova correção na compilação, Bun serve respostas em submilissegundos, e o servidor produz HTML semântico com costuras Alpine.js leves."
          }
      , values:
          { heading: "Os nossos valores"
          , intro: "Estes princípios guiam cada decisão arquitetural do framework."
          , items:
              { one: { title: "Base antes da moda", description: "Preferir fundações comprovadas — HTML tipado, erros explícitos e renderização server-first — em vez da moda da semana." }
              , two: { title: "Aberto por padrão", description: "Invariantes de segurança, portões de política e convenções são documentados e testáveis para que os contribuidores raciocinem sobre o sistema." }
              , three: { title: "Aprender sempre", description: "ADRs, evals e docs de convenção registam o que aprendemos para que a próxima mudança parta de contexto partilhado." }
              , four: { title: "Costuras de apoio", description: "A interatividade Alpine permanece tipada e mínima — polish de UX sem contrabandear um runtime de cliente." }
              , five: { title: "Assumir a responsabilidade", description: "Erros são valores, a CSP está fixa, e as caches são conservadoras porque surpresas em produção são o nosso problema, não do usuário." }
              , six: { title: "Gostar da contenção", description: "Uma superfície pequena que cabe na cabeça vale mais do que uma caixa de ferramentas máxima a combater em cada feature." }
              }
          }
      }
  , contact:
      { title: "Comunidade e contribuição"
      , subtitle: "Reporte problemas, participe nas discussões ou inspecione o código diretamente no GitHub."
      , issuesTag: "Issues"
      , issuesTitle: "Relatórios de bugs e issues"
      , issuesText: "Encontrou um bug, caso limite ou comportamento inesperado? Abra uma issue no GitHub com passos de reprodução."
      , issuesButton: "Abrir uma issue"
      , discussionsTag: "Comunidade"
      , discussionsTitle: "Discussões e Q&A"
      , discussionsText: "Tem perguntas de arquitetura, propostas de design, ou quer discutir PureScript e Bun?"
      , discussionsButton: "Juntar-se às discussões"
      , sourceTag: "Código"
      , sourceTitle: "Código-fonte e invariantes"
      , sourceText: "Explore o repositório, inspecione as garantias de segurança verificadas ou envie um pull request no GitHub."
      , sourceButton: "Ver o repositório"
      }
  , posts:
      { listTitle: "Notas de engenharia"
      , listSubtitle: "Stack, convenções e garantias."
      , detailTitle: "Artigo"
      , articleTagPrefix: "Artigo n.º"
      , readMore: "Ler artigo"
      , backToList: "Voltar aos artigos"
      , loadingError: "Falha ao carregar artigos. Verifique sua conexão."
      , notFound: "Artigo não encontrado."
      , byAuthor: "Por"
      , authorRole: "Engenharia"
      , unknownAuthor: "Pohjola"
      }
  , fixtures:
      { listTitle: "Calendário"
      , subtitle: "Próximos jogos do Tottenham Hotspur — calendário via OneFootball."
      , homeLabel: "Casa"
      , awayLabel: "Fora"
      , homeVenue: "Tottenham Hotspur Stadium"
      , awayVenue: "Jogo fora"
      , sourceLabel: "THFC"
      , vsLabel: "x"
      }
  , footer:
      { explore: "Navegação"
      , resources: "Recursos"
      , github: "Código-fonte"
      , issues: "Rastreador de bugs"
      , copyright: "© 2026 Pohjola Framework. Software open source."
      }
  , seo:
      { homeDescription: "O framework web funcional e tipado para Bun, PureScript e Alpine.js"
      , aboutDescription: "Saiba mais sobre o Pohjola."
      , contactDescription: "Entre em contato com a comunidade Pohjola."
      , postsDescription: "Leia notas de engenharia e destaques de arquitetura do Pohjola."
      , postDetailDescription: "Uma nota de engenharia sobre o Pohjola."
      , fixturesDescription: "Próximos jogos do Tottenham Hotspur para a temporada de 2026."
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
      }
  }

-- | Select the dictionary for a given language
dict :: Lang -> Dictionary
dict En = en
dict Fr = fr
dict Pt = pt

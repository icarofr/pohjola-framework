-- | Data service — provides curated engineering notes or fetches from an external API.
-- |
-- | Demonstrates the data layer pattern: boundary functions return
-- | `Aff (Either AppError a)`. Callers pattern-match exhaustively.
-- | Errors are values (AppError), not exceptions.
-- |
-- | In a customised deployment, configure POSTS_API_BASE to point to your CMS
-- | (Directus, Contentful, Strapi). The pattern stays the same: Bun native fetch
-- | via App.FetchBun -> Argonaut decode -> Either.
module App.Features.Posts.Service
  ( curatedPosts
  , fetchPost
  , fetchPosts
  ) where

import Prelude

import App.Config (Config)
import App.Data.Fetch (fetchJson)
import App.Error (AppError(..))
import App.Features.Posts.Types (Post(..))
import Data.Array as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)

-- | Real engineering articles explaining Pohjola's architecture and design.
curatedPosts :: Array Post
curatedPosts =
  [ Post
      { id: 1
      , userId: 1
      , title: "Why Functional SSR on Bun Matters"
      , body: "Building web applications with PureScript and Bun combines compile-time totality with sub-millisecond execution.\n\nUnlike traditional Node.js runtimes that carry heavy startup and module resolution overhead, Bun serves pre-rendered HTML in under a millisecond. Paired with PureScript's closed algebraic HTML data type, views are rendered as pure values, eliminating runtime exceptions and guaranteeing XSS safety before a single byte touches the wire."
      }
  , Post
      { id: 2
      , userId: 1
      , title: "Eliminating the Hydration Cliff with Alpine.js"
      , body: "Single-page application frameworks require downloading megabytes of client JavaScript just to re-render markup that the server already produced.\n\nPohjola eliminates the hydration cliff by coupling server-rendered HTML with Alpine.js morphing. Hovering over a navigation link pre-fetches the target HTML fragment in the background. On click, Alpine swaps the content container instantaneously, delivering SPA speed with zero client state drift."
      }
  , Post
      { id: 3
      , userId: 1
      , title: "Total Type Safety Across HTTP and HTML"
      , body: "In conventional frameworks, routing, API payloads, and HTML generation exist across loose string boundaries where typos and breaking changes hide.\n\nIn Pohjola, routes are bidirectional codecs verified by routing-duplex. HTML is constructed through algebraic constructors rather than string templates. If a route or translation key changes, the compiler immediately rejects any broken references across the entire codebase."
      }
  , Post
      { id: 4
      , userId: 1
      , title: "Taming the Foreign Function Interface (FFI)"
      , body: "JavaScript interop is often the weakest link in statically typed web applications.\n\nPohjola enforces a strict FFI safety floor: all foreign JavaScript imports are restricted to four allowlisted modules. Every FFI boundary is wrapped in PureScript types, converting untrusted runtime errors into explicit Either values that must be handled at the call site."
      }
  , Post
      { id: 5
      , userId: 1
      , title: "Mechanical Guarantees Over Documentation Conventions"
      , body: "Conventions rot; mechanical assertions endure.\n\nEvery commit in Pohjola is validated against byte-exact Content Security Policy nonces, closed HTML ADT rules, and feature isolation constraints. Running make gate and ContractSpec verifies architectural invariants in under two seconds, ensuring that security and architectural rules remain unbroken as the project evolves."
      }
  , Post
      { id: 6
      , userId: 1
      , title: "Zero-Drift Architecture for Human and AI Pairs"
      , body: "AI coding assistants thrive when constraints are unambiguous and mechanically enforced.\n\nBecause Pohjola expresses routes, translations, and domain effects through exhaustive types, an AI agent cannot invent invalid endpoints or forget error handlers without triggering a compile error. The compiler acts as an unyielding guardrail for human and agentic pair programming."
      }
  , Post
      { id: 7
      , userId: 1
      , title: "Hypermedia as the Engine of Application State (HATEOAS)"
      , body: "Why replicate complex state machines and API schemas across client and server when hypermedia already solves distributed state?\n\nIn Pohjola, application state transitions are driven by hypermedia representations. The server emits semantic HTML where available actions, disabled controls, and navigation links reflect the exact server resource state. Paired with PureScript's closed algebraic Html ADT and Alpine AJAX fragment morphing, HATEOAS delivers fluid, reactive client experiences with total compile-time guarantees."
      }
  ]

-- | Fetch all posts. Uses external API if configured; otherwise serves curated posts.
fetchPosts :: Config -> Aff (Either AppError (Array Post))
fetchPosts cfg =
  if cfg.postsApiBase /= "https://jsonplaceholder.typicode.com" && cfg.postsApiBase /= "" then
    fetchJson (cfg.postsApiBase <> "/posts")
  else
    pure (Right curatedPosts)

-- | Fetch a single post by ID.
fetchPost :: Config -> Int -> Aff (Either AppError Post)
fetchPost cfg id =
  if cfg.postsApiBase /= "https://jsonplaceholder.typicode.com" && cfg.postsApiBase /= "" then
    fetchJson (cfg.postsApiBase <> "/posts/" <> show id)
  else
    case Array.find (\(Post p) -> p.id == id) curatedPosts of
      Just post -> pure (Right post)
      Nothing -> pure (Left NotFound)

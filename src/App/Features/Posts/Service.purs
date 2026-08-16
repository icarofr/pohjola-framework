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
  ( createPost
  , curatedPosts
  , fetchPost
  , fetchPosts
  ) where

import Prelude

import App.Config (Config)
import App.Data.Fetch (fetchJson)
import App.Data.SQL as SQL
import App.Error (AppError(..))
import App.Features.Posts.Types (Post(..))
import Data.Argonaut.Decode.Error (JsonDecodeError(..))
import Data.Array as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)

-- | Decode a database row into a Post domain value.
decodePostRow :: SQL.DbRow -> Maybe Post
decodePostRow row = do
  id <- SQL.readIntField row "id"
  title <- SQL.readStringField row "title"
  body <- SQL.readStringField row "body"
  let userId = fromMaybe 1 (SQL.readIntField row "user_id")
  pure $ Post { id, userId, title, body }

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
      , title: "Hypermedia as the Engine of Application State (HATEOAS)"
      , body: "Why replicate complex state machines and API schemas across client and server when hypermedia already solves distributed state?\n\nIn Pohjola, application state transitions are driven by hypermedia representations. The server emits semantic HTML where available actions, disabled controls, and navigation links reflect the exact server resource state. Paired with PureScript's closed algebraic Html ADT and Alpine AJAX fragment morphing, HATEOAS delivers fluid, reactive client experiences with total compile-time guarantees."
      }
  , Post
      { id: 4
      , userId: 1
      , title: "Total Type Safety Across HTTP and HTML"
      , body: "In conventional frameworks, routing, API payloads, and HTML generation exist across loose string boundaries where typos and breaking changes hide.\n\nIn Pohjola, routes are bidirectional codecs verified by routing-duplex. HTML is constructed through algebraic constructors rather than string templates. If a route or translation key changes, the compiler immediately rejects any broken references across the entire codebase."
      }
  , Post
      { id: 5
      , userId: 1
      , title: "Taming the Foreign Function Interface (FFI)"
      , body: "JavaScript interop is often the weakest link in statically typed web applications.\n\nPohjola enforces a strict FFI safety floor: all foreign JavaScript imports are restricted to four allowlisted modules. Every FFI boundary is wrapped in PureScript types, converting untrusted runtime errors into explicit Either values that must be handled at the call site."
      }
  , Post
      { id: 6
      , userId: 1
      , title: "Mechanical Guarantees and Zero-Drift for AI Pairs"
      , body: "Conventions rot; mechanical assertions endure.\n\nEvery commit in Pohjola is validated against byte-exact Content Security Policy nonces, closed HTML ADT rules, and feature isolation constraints. Running make gate and ContractSpec verifies architectural invariants in under two seconds. Because routes, translations, and domain effects are expressed through exhaustive types, AI coding agents and humans cannot introduce breaking changes or hallucinate missing handlers without triggering immediate compiler errors."
      }
  ]

-- | Fetch all posts. Queries PostgreSQL when DATABASE_URL is configured;
-- | otherwise fetches from external API or serves local curated posts.
fetchPosts :: Config -> Aff (Either AppError (Array Post))
fetchPosts cfg = case cfg.databaseUrl of
  Just dbUrl -> do
    sql <- liftEffect $ SQL.connect dbUrl
    result <- SQL.query sql "SELECT id, user_id, title, body FROM posts ORDER BY id ASC" []
    case result of
      Left err -> pure (Left (DecodeError (TypeMismatch (show err))))
      Right rows -> do
        let posts = Array.mapMaybe decodePostRow rows
        if Array.null posts then
          pure (Right curatedPosts)
        else
          pure (Right posts)
  Nothing ->
    if cfg.postsApiBase /= "https://jsonplaceholder.typicode.com" && cfg.postsApiBase /= "" then
      fetchJson (cfg.postsApiBase <> "/posts")
    else
      pure (Right curatedPosts)

-- | Fetch a single post by ID.
fetchPost :: Config -> Int -> Aff (Either AppError Post)
fetchPost cfg id = case cfg.databaseUrl of
  Just dbUrl -> do
    sql <- liftEffect $ SQL.connect dbUrl
    result <- SQL.query sql "SELECT id, user_id, title, body FROM posts WHERE id = $1 LIMIT 1" [ SQL.SqlInt id ]
    case result of
      Left _ -> pure (Left NotFound)
      Right rows -> case Array.head (Array.mapMaybe decodePostRow rows) of
        Just post -> pure (Right post)
        Nothing -> pure (Left NotFound)
  Nothing ->
    if cfg.postsApiBase /= "https://jsonplaceholder.typicode.com" && cfg.postsApiBase /= "" then
      fetchJson (cfg.postsApiBase <> "/posts/" <> show id)
    else
      case Array.find (\(Post p) -> p.id == id) curatedPosts of
        Just post -> pure (Right post)
        Nothing -> pure (Left NotFound)

-- | Create a new post in SQL storage when DATABASE_URL is configured.
createPost :: Config -> Post -> Aff (Either AppError Int)
createPost cfg (Post post) = case cfg.databaseUrl of
  Just dbUrl -> do
    sql <- liftEffect $ SQL.connect dbUrl
    result <- SQL.execute sql "INSERT INTO posts (id, user_id, title, body) VALUES ($1, $2, $3, $4)"
      [ SQL.SqlInt post.id, SQL.SqlInt post.userId, SQL.SqlString post.title, SQL.SqlString post.body ]
    case result of
      Left err -> pure (Left (DecodeError (TypeMismatch (show err))))
      Right _ -> pure (Right post.id)
  Nothing ->
    pure (Right post.id)

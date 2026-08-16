-- | FFI bindings to Bun native utilities — SIMD-accelerated escapeHTML,
-- | XML.stringify for sitemap generation, and Bun-native file/hash helpers
-- | for the migration runner (Bun.file + Glob + Bun.SHA256 — no node:fs).
-- |
-- | The PS side stays pure; the JS side is plumbing only (ADR-007).
module App.Bun where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)
import Effect (Effect)
import Effect.Aff (Aff, makeAff)
import Foreign (Foreign)

-- | SIMD-accelerated HTML escaping via Bun.escapeHTML.
-- | Escapes & < > " ' — same set as App.Html.escape, but native.
-- | Note: Bun uses &#x27; for single quotes; PS escape used &#39;.
-- | Both are valid HTML5 entities.
foreign import escapeHTMLImpl :: String -> String

-- | Bun.XML.stringify — serializes a Bun.XML.Node tree to an XML string.
-- | The Node shape: { name: String, attributes: { [k]: String },
-- |   children: Array (Node | String) }
-- | Returns null on failure (lifted to Maybe via Data.Nullable).
foreign import stringifyXMLImpl :: Foreign -> Nullable String

-- | Read a file as UTF-8 text via Bun.file(path).text().
-- | Async — two-callback pattern (onSuccess/onError) so PS wraps via makeAff.
-- | Returns Left with the error message on failure (missing file, I/O, etc.),
-- | Right content on success. Distinguishes "missing" from "read error".
-- | Used by the migration runner to read .sql files — no node:fs.
foreign import readTextFileImpl
  :: String
  -> (String -> Effect Unit)
  -> (String -> Effect Unit)
  -> Effect Unit

-- | List files under a directory matching a glob pattern via Bun's Glob.
-- | Returns an Array of paths (relative to cwd). Empty if none match.
-- | Used by the migration runner to discover migrations/*.sql — no node:fs.
foreign import glob :: String -> Effect (Array String)

-- | SHA-256 hash of a string, hex-encoded, via Bun.SHA256.hash.
-- | Used by the migration runner to checksum migration files.
foreign import sha256Hex :: String -> Effect String

-- | Check if a file exists (sync, via Bun.file().exists()).
foreign import exists :: String -> Effect Boolean

-- | Write UTF-8 text to a file via Bun.write(path, content).
foreign import writeTextFileImpl
  :: String
  -> String
  -> (Unit -> Effect Unit)
  -> (String -> Effect Unit)
  -> Effect Unit

-- | Get command-line arguments (Bun.argv.slice(2)).
foreign import getArgs :: Effect (Array String)

-- | Nanosecond 64-bit non-cryptographic hash via Bun.hash.wyhash.
-- | Formats output as hex string. Ideal for ETags, cache keys, and checksums.
foreign import wyhash :: String -> String

foreign import hashPasswordImpl
  :: String
  -> (String -> Effect Unit)
  -> (String -> Effect Unit)
  -> Effect Unit

foreign import verifyPasswordImpl
  :: String
  -> String
  -> (Boolean -> Effect Unit)
  -> (String -> Effect Unit)
  -> Effect Unit

-- | Hash a password using native Argon2id via Bun.password (SIMD multithreaded).
hashPassword :: String -> Aff (Either String String)
hashPassword password =
  makeAff \callback -> do
    hashPasswordImpl password
      (\hash -> callback (pure (Right hash)))
      (\err -> callback (pure (Left err)))
    pure mempty

-- | Verify a plaintext password against an Argon2id/Bcrypt hash via Bun.password.
verifyPassword :: String -> String -> Aff (Either String Boolean)
verifyPassword password hash =
  makeAff \callback -> do
    verifyPasswordImpl password hash
      (\matches -> callback (pure (Right matches)))
      (\err -> callback (pure (Left err)))
    pure mempty

-- | Safe wrapper: lifts the nullable FFI result to Maybe.
stringifyXML :: Foreign -> Maybe String
stringifyXML = toMaybe <<< stringifyXMLImpl

-- | Read a file as UTF-8 text. Returns Left with the error message on
-- | failure (file missing, permissions, I/O), Right content on success.
readTextFile :: String -> Aff (Either String String)
readTextFile path =
  makeAff \callback -> do
    readTextFileImpl path
      (\content -> callback (pure (Right content)))
      (\err -> callback (pure (Left err)))
    pure mempty -- no canceler: local disk reads don't need abort

-- | Write UTF-8 text to a file. Returns Left with the error message on failure.
writeTextFile :: String -> String -> Aff (Either String Unit)
writeTextFile path content =
  makeAff \callback -> do
    writeTextFileImpl path content
      (\_ -> callback (pure (Right unit)))
      (\err -> callback (pure (Left err)))
    pure mempty


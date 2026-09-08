// App.Bun.js
// Bun native utility bindings — SIMD-accelerated escapeHTML, XML.stringify,
// and Bun-native file/hash helpers for the migration runner
// (Bun.file + Glob + Bun.SHA256 — no node:fs).
// Plumbing only, no app logic (ADR-007).
//
// Tests run under Bun (make test uses bun -e, not spago test/Node),
// so Bun native APIs are always available. No Node fallback needed.
//
// PS FFI calls are curried. Callback pattern (like fetchImpl):
//   onSuccess(result) returns a thunk; onSuccess(result)() executes it.
//   onError(message) likewise. PS wraps via makeAff.

// escapeHTMLImpl :: String -> String
export function escapeHTMLImpl(s) {
  return Bun.escapeHTML(s);
}

// stringifyXMLImpl :: Foreign -> Nullable String
// Returns null on failure (PS lifts to Nothing via the FFI nullable mapping).
export function stringifyXMLImpl(node) {
  try {
    var result = Bun.XML.stringify(node);
    return result === undefined ? null : result;
  } catch (e) {
    return null;
  }
}

// readTextFileImpl :: String -> (String -> Effect Unit) -> (String -> Effect Unit) -> Effect Unit
// Bun.file(path).text() — async. Two-callback pattern (like queryImpl):
//   onSuccess(content) on success, onError(message) on failure.
// Distinguishes "file missing" from "read error" — PS lifts to Either.
export function readTextFileImpl(path) {
  return function (onSuccess) {
    return function (onError) {
      return function () {
        Bun.file(path)
          .text()
          .then(function (content) { onSuccess(content)(); })
          .catch(function (err) { onError(err.message || String(err))(); });
      };
    };
  };
}

// glob :: String -> Effect (Array String)
// Bun-native Glob.scanSync — sync, returns matching paths relative to cwd.
export function glob(pattern) {
  return function () {
    var g = new Bun.Glob(pattern);
    return Array.from(g.scanSync());
  };
}

// sha256Hex :: String -> Effect String
// Bun.SHA256.hash — sync, hex-encoded.
export function sha256Hex(text) {
  return function () {
    return Bun.SHA256.hash(text, "hex");
  };
}

// exists :: String -> Effect Boolean
// Bun.file(path).exists() — sync.
export function exists(path) {
  return function () {
    return Bun.file(path).exists();
  };
}

// writeTextFileImpl :: String -> String -> (Unit -> Effect Unit) -> (String -> Effect Unit) -> Effect Unit
// Bun.write(path, content) — async.
export function writeTextFileImpl(path) {
  return function (content) {
    return function (onSuccess) {
      return function (onError) {
        return function () {
          Bun.write(path, content)
            .then(function () { onSuccess()(); })
            .catch(function (err) { onError(err.message || String(err))(); });
        };
      };
    };
  };
}

// getArgs :: Effect (Array String)
// CLI arguments slice(2) via Bun.argv
export function getArgs() {
  return Bun.argv.slice(2);
}

// wyhash :: String -> String
// Nanosecond 64-bit non-cryptographic hash via Bun.hash.wyhash
export function wyhash(str) {
  return Bun.hash.wyhash(str).toString(16);
}

// randomBase64 :: Int -> Effect String
// N random bytes via the Web Crypto API (crypto.getRandomValues — native to
// Bun's engine, same primitive App.ServerBun.js's CSP nonce generator uses),
// base64-encoded.
export function randomBase64(n) {
  return function () {
    return btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(n))));
  };
}

// randomLuciaId :: Int -> Effect String
// Exact port of Lucia's own generateRandomId (auth_session.ts): each random
// byte's top 5 bits (byte >> 3) index a 32-char human-readable alphabet
// (a-z0-9 without l/o/0/1, to avoid visual ambiguity). 5 bits of entropy
// per byte requested, not 8.
const LUCIA_ID_ALPHABET = "abcdefghijkmnpqrstuvwxyz23456789";
export function randomLuciaId(n) {
  return function () {
    const bytes = new Uint8Array(n);
    crypto.getRandomValues(bytes);
    let id = "";
    for (let i = 0; i < bytes.length; i++) {
      id += LUCIA_ID_ALPHABET[bytes[i] >> 3];
    }
    return id;
  };
}

// hashPasswordImpl :: String -> (String -> Effect Unit) -> (String -> Effect Unit) -> Effect Unit
// Native Argon2id password hashing via Bun.password (SIMD-accelerated background thread).
// memoryCost/timeCost match Lucia's own stated minimum (auth.pilcrowonpaper.com/passwords):
// "Argon2id with at least 16MiB of memory, 3 iterations" -- 16384 KiB = 16 MiB.
// Bun.password.verify reads parameters back out of the stored hash string itself,
// so these values don't need to be passed again at verify time.
export function hashPasswordImpl(password) {
  return function (onSuccess) {
    return function (onError) {
      return function () {
        Bun.password.hash(password, { algorithm: "argon2id", memoryCost: 16384, timeCost: 3 })
          .then(function (hash) { onSuccess(hash)(); })
          .catch(function (err) { onError(err.message || String(err))(); });
      };
    };
  };
}

// verifyPasswordImpl :: String -> String -> (Boolean -> Effect Unit) -> (String -> Effect Unit) -> Effect Unit
// Native password verification via Bun.password
export function verifyPasswordImpl(password) {
  return function (hash) {
    return function (onSuccess) {
      return function (onError) {
        return function () {
          Bun.password.verify(password, hash)
            .then(function (match) { onSuccess(match)(); })
            .catch(function (err) { onError(err.message || String(err))(); });
        };
      };
    };
  };
}



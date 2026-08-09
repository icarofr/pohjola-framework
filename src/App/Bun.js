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

// App.Bun.js
// Bun native utility bindings — SIMD-accelerated escapeHTML + XML.stringify.
// Plumbing only, no app logic (ADR-007).
//
// Tests run under Bun (make test uses bun -e, not spago test/Node),
// so Bun native APIs are always available. No Node fallback needed.

// escapeHTMLImpl :: String -> String
export function escapeHTMLImpl(s) {
  return Bun.escapeHTML(s);
}

// stringifyXMLImpl :: Foreign -> Maybe String
// Returns null on failure (PS lifts to Nothing via the FFI nullable mapping).
export function stringifyXMLImpl(node) {
  try {
    var result = Bun.XML.stringify(node);
    return result === undefined ? null : result;
  } catch (e) {
    return null;
  }
}

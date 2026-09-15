Type: task
Status: resolved

## Question

`App.Cli.ExportStatic.rootRedirectHtml` hand-built its own doctype/html/head/body directly instead of calling `renderShell` (the document-shell seam unified earlier this session). This wasn't hypothetical: it was already the one exported page missing a `lang` attribute and any CSP meta tag.

## Blocked by

None (can start immediately)

## Answer

Built the redirect's head content (charset, refresh meta, canonical link, CSP meta tag via the existing `cspMetaTag`) as an `Html` value the same way `renderErrorPage` does, and called `renderShell defaultLang nonce headContent bodyContent` instead of assembling `doctype <> el "html" [...]` by hand. `rootRedirectHtml` now takes `nonce` as a second argument; updated its one call site in `runExportStatic`.

Verified: `make gate` (20/20), `make test` (234/234), `make format-check`, `make assets-check`, `make build` all green. Ran a real `make export-static OUT=/tmp/export-smoke-test` and inspected the output `index.html` directly: `<html lang="en">` present, a real `Content-Security-Policy` meta tag present, meta-refresh and canonical link unchanged, body now also carries `bodyClass` (a bonus consistency fix from routing through the shared skeleton).

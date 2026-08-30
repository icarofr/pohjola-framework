# Forms — App.Form contract

`src/App/Form.purs` is the single source of truth for every form: field
names, API paths (`apiContactPath`/`apiNewsletterPath`), `FormStatus`,
`EmailAddress` (newtype via `mkEmailAddress`), and the `decodeX` functions.
Views import these; handlers decode them. Keep field names and paths in
`App.Form` — views and handlers reference them, never duplicate them.

## Rules

- **Honeypot semantics** — a filled honeypot means silent SUCCESS (303 with
  `status=success` / `status=subscribed`), NOTHING sent. Bots believe they
  won. The trap is silent on the wire (303 success), but warn-logged
  server-side with the request id; log the request id only, never the
  honeypot value or PII. Property-tested for all inputs.
- **Same-origin gate** (`Main.sameOriginOk`) — `Origin` header present → must
  equal `cfg.baseUrl`; absent → allowed. POSTs only.
- **Parsing** — `Data.FormURLEncoded.decode`. Use this, not hand-rolled
  parsing.
- **Status banners** — `?status=success|error|subscribed` rendered via
  `maybeStatusBanner` with `data-form-status` + localized `statusText`.

## Form UI helpers (`App.Ui.Form`)

Use `src/App/Ui/Form.purs` for rendering form containers and inputs when you
add a page that needs one. No demo page currently renders these helpers, but
`/api/contact` and `/api/newsletter` handlers in `App.Main` are wired for when
you do.
- `formContainer` — wraps form with automatic `lang` hidden field and honeypot field.
- `textField`, `emailField`, `textareaField` — styled inputs with dark mode, labels, and required flags.
- `submitButton` — accessible Tailwind button with hover/focus states.
- `renderStatusBanner` — accessible feedback banners for `FormSuccess`/`FormError`.

## Adding a form

Extend `App.Form` with a new `decodeX` following `decodeContact`/
`decodeNewsletter` (new Submission sum + decoder + field-name record + API
path constant), render via `App.Ui.Form`, then add the handler in `Main.purs` following the existing
ones. Parse form bodies through `App.Form` — inline parsing in handlers
fails ContractSpec / property tests.

**Done when**: `make check` passes and the form submits successfully with
both valid and honeypot inputs (303 success for both).

Prefer parallel `decodeX` functions until 5+ forms exist; extract a generic
decoder then, not before.

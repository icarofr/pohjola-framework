# Forms — App.Form contract

`src/App/Form.purs` is the single source of truth for every form: field
names, `FormStatus`, `EmailAddress` (newtype via `mkEmailAddress`), and
the `decodeX` functions. Handlers decode through `App.Form`. Keep field
names in `App.Form` — views and handlers reference them, never
duplicate them.

## Rules

- **Honeypot semantics** — a filled honeypot means silent SUCCESS (303 with
  `status=success` / `status=subscribed`), NOTHING sent. Bots believe they
  won. The trap is silent on the wire (303 success), but warn-logged
  server-side with the request id; log the request id only, never the
  honeypot value or PII. Property-tested for all inputs.
- **Same-origin gate** — removed along with the last mutating route
  (Contact/newsletter POST, see the note below and `App.Main`'s
  entry-point comment). A form's handler needs a same-origin or
  `Sec-Fetch-Site` check before it POSTs anywhere real; see
  `docs/GUARANTEES.md`'s CSRF (ADR-005) section for the current state of
  that hierarchy before wiring one back in.
- **Parsing** — `Data.FormURLEncoded.decode`. Use this, not hand-rolled
  parsing.
- **Status banners** — `?status=success|error|subscribed` rendered via
  SiteShell / `maybeStatusBanner` with `data-form-status` + localized
  `statusText` (status is applied when `renderPage` wraps the body).

## Visible form UI (`PageTemplate` Form)

Feature views must **not** import `App.Ui.Form`. The legal path is:

1. Decode in `App.Form` (unchanged).
2. Handler in `Main` (unchanged).
3. **Visible form:** `PageTemplate` constructor `Form` + `FormSlots` /
   `FormField` records in **View.purs**, via
   `App.Ui.Templates.Render.renderPage`.
4. **Forbidden:** `import App.Ui.Form` in `App.Features` — gate fails.

`App.Ui.Templates.Form` owns DaisyUI fieldset rendering and calls
`App.Ui.Form` helpers (`formContainer`, `textField`, `emailField`,
`textareaField`, `submitButton`) internally. Honeypot name is `"website"`
(same as `contactFields` / `newsletterFields`).

The clean-sheet rebuild removed Contact, Home's newsletter signup, and
both `/api/contact`/`/api/newsletter` HTTP routes — no page currently
POSTs to either (see `App.Main`'s entry-point comment). The decode/
honeypot kernel (`contactFields`, `newsletterFields`, `decodeContact`,
`decodeNewsletter`) is untouched and still directly unit-tested
(`test/FormSpec.purs`); only the page-specific HTTP glue was removed.
Reintroducing a form is a page-content decision for whichever ticket
wants one, not assumed here.

## Adding a form

1. Extend `App.Form` with a new `decodeX` following `decodeContact` /
   `decodeNewsletter` (Submission sum + decoder + field-name record + API
   path constant).
2. Add a handler in `Main.purs` following the existing ones.
3. In the feature `View.purs`, call `renderPage` with
   `Form { title, subtitle, breadcrumbs, action, submitLabel, fields }`.
   Map fields with `FormText` / `FormEmail` / `FormTextarea` from
   `App.Ui.Templates.Types`.
4. Parse form bodies through `App.Form` — inline parsing in handlers
   fails ContractSpec / property tests.

**Done when**: `make check` passes and the form submits successfully with
both valid and honeypot inputs (303 success for both).

Prefer parallel `decodeX` functions until 5+ forms exist; extract a generic
decoder then, not before.

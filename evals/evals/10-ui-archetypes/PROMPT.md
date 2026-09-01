# Eval 10: UI templates

Add a static "Team" page using the correct `PageTemplate` for its purpose. Read `docs/superpowers/specs/2026-08-31-page-architectures.md` first — prefer `Editorial` for a simple static page; use `Schedule` for match/fixture lists (never `Feed`). Do not use `class_` or primitive soup (`import App.Ui.Card`, etc.) in the feature view. Call `App.Ui.Templates.Render.renderPage` with slot records only.

# Pohjola — Agent Guide

PureScript 0.15.16 + Bun SSR MPA. Alpine AJAX swaps the SiteShell drawer `#content` (not `<main>`). No custom browser JS.

## Safety floor
- dist/ public static; dist-server/ private bundle
- App.Alpine constructors only (ADR-000)
- FFI: Policy.Contract ffiAllowlist (four modules). Extend App.Bun for new Bun primitives; do not add a fifth module without ADR-003.
- make gate = Policy.Contract. No class_ in Features. Every View.purs imports App.Ui.Templates.Render.
- CSP pinned in ContractSpec. Do not widen. unsafe-eval is required by Alpine (new Function).
- Do not implement ADR-010. Do not import App.Auth.Scaffold into Main or Features (ADR-002 pending).
- Licence: AGPL. Do not paste private app names into this public tree.

## Commands
make deps | make dev | make gate | make test | make check | make new-feature NAME=X WIRE=1 [CHROME=1] [TYPE=data]
make eval EVAL=01-add-page          # prompt
make eval EVAL=01-add-page CHECK=1  # assertions

## One architecture
- Document wrapper: App.Layout.Page.renderDocument
- Page body: App.Ui.Templates.Render.renderPage lang route status template
- Static feature: Page.purs (staticPage) + View.purs (slots). Data: + Types + Service.
- Copy: Data.I18n Dictionary, every allLangs. Chrome labels from dict, not hardcoded.
- Errors: Either AppError. Forms: App.Form decode + Form PageTemplate for UI.

## Task → one doc
| Task | Doc |
| add page | docs/superpowers/specs/2026-08-31-page-architectures.md then make new-feature |
| chrome | docs/conventions/chrome-checklist.md |
| Alpine | docs/conventions/alpine-contracts.md |
| FFI | docs/ffi-taming-guide.md |
| forms | docs/conventions/forms.md |
| tests | docs/conventions/testing-recipes.md |
| deploy | docs/conventions/server.md |
| new language | docs/conventions/adding-a-language.md |
| claims | docs/GUARANTEES.md |
| auth | docs/adr/ADR-002-auth-shape.md (do not code) |

Skip docs/SETUP.md unless a human asks. Exemplars: About (static), Posts (data). Grep those before README samples.

## Verify
make gate after the first compile. make test if you touched Alpine, cache, forms, templates, or Main. make check before commit.
When the verify method is unclear, ask.

## Evals
After a convention change, run the matching eval CHECK=1 (01 page, 11 chrome, 12 UI, 10 archetypes).

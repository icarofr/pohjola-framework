# Generators — scaffolding & codegen contracts

## Scaffold a new feature

`scripts/auto-scaffold.js` is the canonical feature generator (Bun). Invoke it via
`make new-feature` — do not add parallel shell generators.

```bash
make new-feature NAME=Team                    # static page (default)
make new-feature NAME=Products TYPE=data      # data-backed page
make new-feature NAME=Team WIRE=1             # auto-wire into Route, Main, I18n, and Head!
make new-feature NAME=Team WIRE=1 CHROME=1    # also wire SiteShell nav (desktop, mobile, footer)
make new-feature NAME=Team SLUG_FR=equipe     # custom FR slug
```

Creates `src/App/Features/<Name>/` with the standard file split. When `WIRE=1` is passed, it automatically wires the feature across `Data.Route`, `App.Main`, `Data.I18n`, and `App.Layout.Head` and validates compilation immediately.

**Navigation:** use `CHROME=1` with `WIRE=1` to auto-wire `SiteShell` nav links, or add manually per [`chrome-checklist.md`](chrome-checklist.md).

Generated views consume `App.Ui.Templates` (`renderPage` + slot records). Pick the template from
[`page-architectures`](../superpowers/specs/2026-08-31-page-architectures.md) before editing the scaffold default (`Editorial`).
Do not add raw Tailwind utility chains to feature views; DaisyUI/layout utilities belong inside Templates / `App.Ui`.

`make generator-policy` validates the canonical generator and its boundary
contract. It is not a full proof of the CSS/type system; existing feature views
may still require migration to current recipes.

## Generate PureScript types from SQL Schema

`src/App/Cli/GenSql.purs` is the canonical SQL codegen entrypoint. `make gen-sql`
builds it and runs the CLI under Bun:

```bash
make gen-sql                                  # generate from migrations/ directory
make gen-sql FILE=migrations/001.sql          # generate from specific file
make gen-sql TABLE=comments OUT=src/App/Features/Comments/Types.purs
```

Inspects PostgreSQL DDL `CREATE TABLE` definitions and automatically generates type-safe PureScript domain types, Argonaute `DecodeJson`/`EncodeJson` codecs, and row record mappings.

## File layout

- **Data-backed**: `Types.purs`, `Page.purs` (fetch + view), optional `Components/`
- **Static**: `Page.purs` only (handler + template slots)

ContractSpec enforces feature isolation — see `test/ContractSpec.purs`.

## Decision rule

- Presence of `Service.purs` ⇒ data-backed feature.
- Data-backed ⇒ `Types.purs` must exist.
- Example: `Posts/` (data-backed) vs `About/` (static).

## Checklist after scaffolding

- `make gate && bun x spago build && make test` passes.
- No new cross-feature imports (ContractSpec isolation test).
- `make check` passes (lint + formatting).

**Done when**: `make check` is green and the feature renders at both
`/en/<route>` and `/fr/<route>`.

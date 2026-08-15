# Generators — scaffolding & codegen contracts

## Scaffold a new feature

```bash
make new-feature NAME=Team                    # static page (default)
make new-feature NAME=Products TYPE=data      # data-backed page
make new-feature NAME=Team WIRE=1             # auto-wire into Route, Main, I18n, and Head!
make new-feature NAME=Team SLUG_FR=equipe     # custom FR slug
```

Creates `src/App/Features/<Name>/` with the standard file split. When `WIRE=1` is passed, it automatically wires the feature across `Data.Route`, `App.Main`, `Data.I18n`, and `App.Layout.Head` and validates compilation immediately.

## Generate PureScript types from SQL Schema

```bash
make gen-sql                                  # generate from migrations/ directory
make gen-sql FILE=migrations/001.sql          # generate from specific file
make gen-sql TABLE=comments OUT=src/App/Features/Comments/Types.purs
```

Inspects PostgreSQL DDL `CREATE TABLE` definitions and automatically generates type-safe PureScript domain types, Argonaute `DecodeJson`/`EncodeJson` codecs, and row record mappings.

## File layout

- **Data-backed**: `Types.purs`, `Service.purs`, `Page.purs`, `View.purs`, `Components/`
- **Static**: `Page.purs`, `View.purs`

ContractSpec enforces feature isolation — see `test/ContractSpec.purs`.

## Decision rule

- Presence of `Service.purs` ⇒ data-backed feature.
- Data-backed ⇒ `Types.purs` must exist.
- Example: `Posts/` (data-backed) vs `About/` (static).

## Checklist after scaffolding

- `make gate && spago build && make test` passes.
- No new cross-feature imports (ContractSpec isolation test).
- `make check` passes (lint + formatting).

**Done when**: `make check` is green and the feature renders at both
`/en/<route>` and `/fr/<route>`.

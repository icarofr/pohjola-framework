# Adding a language

Checklist for introducing a new `Lang` without touching fragment head-sync JavaScript.

1. **`Lang` ADT** — add the constructor in `Data.I18n`, extend `allLangs`, `langTag`, and `parseLang`.
2. **`routeCodec`** — add a branch in `Data.Route.routeCodec` (and any related URL helpers) for the new prefix.
3. **Dictionary** — add a full `dict` instance for every key the existing languages provide.
4. **`ogLocale`** — add a case in `App.Layout.Head.ogLocale` (e.g. `xx_YY`), used by the server-rendered `<head>`.
5. **No JS edits** — `App.Layout.Scripts.pageSyncScript` only syncs `data-page-title`/`data-page-lang` after a fragment swap; neither is language-specific, so a new language needs no changes there.

Chrome copy (nav home, etc.) comes from the dictionary (`d.nav.home`, …), not hardcoded shell helpers.

Verify with `make test`.

# Dev CSS delivery

Type: grilling
Status: resolved
Blocked by: 02

## Question

Keep embedding CSS into Styles.purs on every Tailwind save in dev, or link `/css/styles.css` with no-store when POHJOLA_DEV is set?

## Answer

Two adapters, one `DocumentChrome`. Production and static export stay inlined (`linkedCss: false`). `make dev` sets `POHJOLA_DEV=1`; documents link `/css/styles.css`. Bun directory routes do not emit Cache-Control, so `POHJOLA_DEV` serves `/css/*` (and the other static prefixes) from `fetch` with `no-store` instead of going through `routes`. Tailwind watch writes the file; it does not re-embed into `Styles.purs`.

## Comments

Ported from enora-chartier under full autonomy.

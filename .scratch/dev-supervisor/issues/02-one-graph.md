# One rebuild graph

Type: grilling
Status: resolved
Blocked by: 01

## Question

Keep four overlapping watchers, or one supervisor graph with a process group and shared `make watch`?

## Answer

One supervisor. `scripts/dev.js` owns Tailwind `--watch` (file only, no embed), a `static/` → `dist/` copy, Spago on `.purs` except `Layout/Styles.purs`, and Bun `--watch` on `App.Main`. Children spawn `detached` and are killed as a process group. `make watch` is the same graph with `--no-server`.

## Comments

Ported from enora-chartier under full autonomy.

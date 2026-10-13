Type: task
Status: resolved

## Question

`App.Server.okTextRobots` deliberately serves `robots.txt` with `no-store` — documented as a safety latch, not an afterthought ("a Disallow latch must not survive a day in a CDN HIT"). `App.Cli.ExportStatic` writes the same body via `renderRobots` as a plain static file, with no equivalent guarantee and nothing saying so. Is this worth a design change, or just naming?

## Blocked by

None (can start immediately)

## Answer

Named it rather than designed around it: added a third "Known, accepted gap" paragraph to `ExportStatic`'s module doc, matching the style and treatment of its existing CSP-nonce-sharing gap. An operator-toggleable emergency Disallow for a static export would need a real design (likely: a documented runbook step, or a separate always-fresh `robots.txt` hosted outside the static bundle) — that's a genuine follow-on design question this review surfaced but didn't invent an answer for, left as a note in the doc rather than guessed at in code.

No code behavior change. `make gate`/`make test` unaffected (doc-only diff in this file).

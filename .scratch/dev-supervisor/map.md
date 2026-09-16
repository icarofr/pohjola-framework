# Local-dev supervisor

## Destination

`make dev` is one supervisor: bind from 3000 upward, one rebuild graph, watch `static/`, CSS is a no-store file in dev, live-reload SSE is held and on. Production stays inlined CSS with no live-reload script.

## Notes

- Skills: CONTEXT.md, ADR-003, ADR-007, docs/conventions/server.md.
- Ported from enora-chartier `67c321f` onto pohjola-framework `origin/master`.
- No client bundler, no ADR-010, no fifth FFI module.

## Decisions so far

- [Bind-loop the origin](issues/01-bind-loop.md): bind with Bun.serve (IPv6 dual-stack) from 3000–3099; explicit PORT fails if busy; BASE_URL follows the bound port.
- [One rebuild graph](issues/02-one-graph.md): one supervisor, process-group children, `make watch` is `--no-server`.
- [Dev CSS delivery](issues/03-dev-css.md): two DocumentChrome adapters — link the file in dev, inline in production.
- [Live-reload SSE](issues/04-live-reload.md): held SSE in ServerBun; HeadScript only when liveReload is on.
- [Ship the supervisor](issues/05-ship.md): ported onto origin/master; gate 20/20, test 235 + 6 pick-port.

## Not yet specified

(none)

## Out of scope

- Switching production/static-export to `<link href="/css/styles.css">`.
- Vite / esbuild client bundler.
- Killing leftover listeners from other sessions on bind success (only skip busy ports).
- A HeadScript constructor per library.

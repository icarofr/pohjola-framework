# Live-reload SSE

Type: grilling
Status: resolved
Blocked by: 03

## Question

Keep the one-shot opt-in EventSource, or hold a stream in ServerBun, broadcast on dist/css and dist/assets, emit the HeadScript only in pohjolaDev?

## Answer

Held SSE in `ServerBun.js` (ADR-003 ReadableStream exception, no fifth FFI module). `GET /dev/live-reload` stays open with a 15s heartbeat; `dist/css` and `dist/assets` broadcasts `data: reload`. `DevLiveReload` is emitted only when `DocumentChrome.liveReload` is on. Production documents must not contain the EventSource.

## Comments

Ported from enora-chartier under full autonomy.

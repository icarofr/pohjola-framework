# Bind-loop the origin

Type: grilling
Status: resolved
Blocked by:

## Question

Connect-probe 3000 then 3001, or bind until the kernel accepts, deriving BASE_URL from that port?

## Answer

Bind-loop. `scripts/pick-port.js` asks `Bun.serve` (the same IPv6 dual-stack bind as `App.ServerBun`) from 3000 through 3099. An explicit `PORT` fails if that port is busy. `BASE_URL` is always `http://localhost:<bound>`. Connect-probe is gone; an IPv4-only `127.0.0.1` listen is also gone — it would miss leftover `*:port` listeners.

## Comments

Ported from enora-chartier under full autonomy.

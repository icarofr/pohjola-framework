// App.ServerBun.js
// Bun.serve binding. Marshalling + ReadableStream lifecycle only; app logic via PS callbacks.
// Live-reload SSE is the same ReadableStream exception as streamResponseImpl (ADR-003).

import { watch } from "node:fs";

const ASSET_CACHE = "public, max-age=31536000, immutable";
const DEV_ASSET_CACHE = "no-store";
const ASSET_HEADERS = {
  "Cache-Control": ASSET_CACHE,
  "CDN-Cache-Control": ASSET_CACHE,
  "Cloudflare-CDN-Cache-Control": ASSET_CACHE,
};
const encoder = new TextEncoder();
const liveReloadClients = new Set();

function isPohjolaDev() {
  return process.env.POHJOLA_DEV === "1";
}

function shouldReadBody(method) {
  return method === "POST" || method === "PUT" || method === "PATCH";
}

function isUnsafeRel(pathname) {
  return pathname.includes("..") || pathname.includes("\\") || pathname.includes("\0");
}

// Bun `{ dir, headers }` currently ignores `headers` (verified: dir responses
// have ETag/Last-Modified and no Cache-Control). Wrap Bun.file so the Guest
// still gets zero-copy sendfile with the year-long policy.
async function cachedAsset(staticRoot, req) {
  const pathname = new URL(req.url).pathname;
  if (isUnsafeRel(pathname)) {
    return new Response("Bad Request", { status: 400 });
  }
  const file = Bun.file(staticRoot + pathname);
  if (!(await file.exists())) {
    return new Response("Not Found", { status: 404 });
  }
  const lastModified = new Date(file.lastModified).toUTCString();
  const etag = `W/"${file.size.toString(16)}-${Math.trunc(file.lastModified).toString(16)}"`;
  return new Response(file, {
    headers: {
      ...ASSET_HEADERS,
      "Last-Modified": lastModified,
      ETag: etag,
    },
  });
}

function devStaticPath(pathname) {
  if (pathname.includes("..") || pathname.includes("\\") || pathname.includes("\0")) {
    return null;
  }
  if (pathname === "/favicon.svg") return pathname;
  if (
    pathname.startsWith("/assets/") ||
    pathname.startsWith("/css/") ||
    pathname.startsWith("/images/")
  ) {
    return pathname;
  }
  return null;
}

function broadcastReload() {
  const payload = encoder.encode("data: reload\n\n");
  for (const client of liveReloadClients) {
    try {
      client.enqueue(payload);
    } catch {
      liveReloadClients.delete(client);
    }
  }
}

function liveReloadStream() {
  let controller;
  let ping;
  return new ReadableStream({
    start(ctrl) {
      controller = ctrl;
      liveReloadClients.add(ctrl);
      ctrl.enqueue(encoder.encode(": connected\n\n"));
      ping = setInterval(() => {
        try {
          ctrl.enqueue(encoder.encode(": ping\n\n"));
        } catch {
          clearInterval(ping);
          liveReloadClients.delete(ctrl);
        }
      }, 15000);
    },
    cancel() {
      if (ping) clearInterval(ping);
      if (controller) liveReloadClients.delete(controller);
    },
  });
}

function watchReload(dir) {
  try {
    let timer;
    watch(dir, { recursive: true }, () => {
      clearTimeout(timer);
      timer = setTimeout(broadcastReload, 80);
    });
  } catch {
    /* directory may not exist yet */
  }
}

function toPsRequest(req, server, body) {
  const url = new URL(req.url);
  return {
    method: req.method,
    url: req.url,
    path: url.pathname,
    query: url.search,
    headers: Object.fromEntries(req.headers),
    // Parsed for future auth (ADR-002); not yet consumed on the PS side.
    // Uses Bun's native CookieMap for spec-compliant cookie parsing.
    //
    // NOTE for whoever implements sessions: ADR-004 pins that App.Session owns
    // ALL cookie encode/decode/verify logic. This parsing predates that module,
    // so it must be routed through App.Session rather than read directly from
    // the request record — otherwise ADR-004 is violated on day one by
    // pre-existing plumbing.
    cookies: typeof Bun !== "undefined" && Bun.CookieMap
      ? Object.fromEntries(new Bun.CookieMap(req))
      : {},
    ip: server.requestIP(req)?.address ?? "unknown",
    body: body,
  };
}

// PS Tuple compiles to { value0, value1 }.
function toWebResponse(psResp) {
  const headers = new Headers();
  for (const t of psResp.headers) headers.set(t.value0, t.value1);
  if (psResp.bodyTag === "StreamBody") {
    return new Response(psResp.bodyStream, { status: psResp.status, headers });
  }
  return new Response(psResp.bodyValue, { status: psResp.status, headers });
}

// Security headers mirrored from App.Server.securityHeaders — applied to
// the JS-side last-resort 500 so every response carries them, even the
// containment path that never reaches PS.
//
// CSP: no 'unsafe-inline' in script-src (nonce-based CSP is injected on the
// PS side per-request; this fallback is text/plain so no scripts execute).
var SECURITY_HEADERS = {
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Content-Security-Policy": "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-eval'",
  "Content-Type": "text/plain; charset=utf-8",
};

// generateNonce :: Effect String
// 18 random bytes → base64 = 24 chars. Meets CSP nonce requirements (≥128 bits).
export function generateNonce() {
  return btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(18))));
}

function makeFetch(handler, staticRoot) {
  return async function fetch(req, server) {
    if (isPohjolaDev()) {
      try {
        const url = new URL(req.url);
        if (url.pathname === "/dev/live-reload") {
          return new Response(liveReloadStream(), {
            headers: {
              "Content-Type": "text/event-stream",
              "Cache-Control": "no-cache",
              Connection: "keep-alive",
            },
          });
        }
        const rel = devStaticPath(url.pathname);
        if (rel) {
          const file = Bun.file(staticRoot + rel);
          if (await file.exists()) {
            return new Response(file, {
              headers: { "Cache-Control": DEV_ASSET_CACHE },
            });
          }
        }
      } catch {
        /* fall through to PS */
      }
    }
    try {
      const body = shouldReadBody(req.method) ? await req.text() : "";
      const psReq = toPsRequest(req, server, body);
      return await new Promise((resolve) => {
        try {
          handler(psReq, (response) => resolve(toWebResponse(response)));
        } catch {
          resolve(new Response("Internal Server Error", {
            status: 500,
            headers: SECURITY_HEADERS,
          }));
        }
      });
    } catch {
      return new Response("Internal Server Error", {
        status: 500,
        headers: SECURITY_HEADERS,
      });
    }
  };
}

// Streaming SSR via ReadableStream's async start + Bun's native fetch.
//
// The stream is populated entirely in the JS event loop — no launchAff_,
// no makeAff, no Aff scheduler. The Aff scheduler doesn't resume forked
// fibers reliably on Bun, so we keep the streaming path in pure JS.
// PS provides synchronous rendering callbacks (pure functions):
//   - onContent: (FetchResult -> StreamContent) — decodes JSON + renders HTML
//   - shellOpen/shellClose: pre-rendered HTML strings
//
// streamResponseImpl(url)(onContent)(shellOpen)(shellClose) -> Effect ReadableStream
export function streamResponseImpl(url) {
  return function (onContent) {
    return function (shellOpen) {
      return function (shellClose) {
        return function () {
          return new ReadableStream({
            async start(controller) {
              try {
                // 1. Shell immediately — browser parses CSS + shows nav
                controller.enqueue(shellOpen);

                if (!url || url === "") {
                  // Local content — PS renders curated posts synchronously
                  const rendered = onContent({ status: 200, body: "" });
                  controller.enqueue(rendered.html);
                } else {
                  try {
                    // 2. Fetch via Bun's native fetch
                    const resp = await fetch(url, {
                      headers: { Accept: "application/json" },
                    });
                    const text = await resp.text();
                    // 3. PS decodes JSON + renders HTML synchronously
                    const rendered = onContent({ status: resp.status, body: text });
                    controller.enqueue(rendered.html);
                  } catch (err) {
                    // Network error — PS renders the error fragment
                    const rendered = onContent({ status: 0, body: String(err) });
                    controller.enqueue(rendered.html);
                  }
                }

                // 4. Closing shell
                controller.enqueue(shellClose);
              } finally {
                controller.close();
              }
            },
          });
        };
      };
    };
  };
}

export function serveImpl(port) {
  return function (staticRoot) {
    return function (handler) {
      return function () {
        const server = Bun.serve({
          port,
          idleTimeout: 30,
          maxRequestBodySize: 64 * 1024,
          routes: isPohjolaDev()
            ? {}
            : {
              "/assets/*": (req) => cachedAsset(staticRoot, req),
              "/css/*": (req) => cachedAsset(staticRoot, req),
              "/images/*": (req) => cachedAsset(staticRoot, req),
              "/favicon.svg": (req) => cachedAsset(staticRoot, req),
            },
          fetch: makeFetch(handler, staticRoot),
        });

        if (isPohjolaDev()) {
          watchReload(staticRoot + "/css");
          watchReload(staticRoot + "/assets");
        }

        // Graceful shutdown — SIGTERM (docker stop) / SIGINT (Ctrl-C).
        // server.stop() (graceful) closes the listener, waits for in-flight
        // requests to finish, then resolves. A 30s backstop force-closes
        // if a request hangs. Idempotent: a second signal force-exits.
        var shuttingDown = false;
        function shutdown() {
          if (shuttingDown) {
            server.stop(true);
            return;
          }
          shuttingDown = true;
          var force = setTimeout(function () {
            server.stop(true);
            process.exit(1);
          }, 30000);
          server.stop().then(function () {
            clearTimeout(force);
            process.exit(0);
          });
        }
        process.on("SIGTERM", shutdown);
        process.on("SIGINT", shutdown);

        return server;
      };
    };
  };
}

// Spike-only (datastar-shell-nav-port branch): a ReadableStream that
// enqueues one already-formatted SSE event body and closes immediately.
export function sseEventStreamImpl(eventBody) {
  return function () {
    return new ReadableStream({
      start(controller) {
        controller.enqueue(new TextEncoder().encode(eventBody));
        controller.close();
      },
    });
  };
}

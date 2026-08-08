// App.ServerBun.js
// Bun.serve binding. Marshalling + ReadableStream lifecycle only; app logic via PS callbacks.
//
// PS FFI calls are curried. PS functions compile to curried JS functions:
//   (a -> b -> Effect Unit) => function(a) { return function(b) { return function() { ... } } }
// PS records compile to JS objects: { status, body } maps to { status: n, body: s }.
// PS Tuple compiles to { value0, value1 }.

function shouldReadBody(method) {
  return method === "POST" || method === "PUT" || method === "PATCH";
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
var SECURITY_HEADERS = {
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Content-Security-Policy": "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'",
  "Content-Type": "text/plain; charset=utf-8",
};

function makeFetch(handler) {
  return async function fetch(req, server) {
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
        return Bun.serve({
          port,
          idleTimeout: 30,
          maxRequestBodySize: 64 * 1024,
          routes: {
            "/assets/*": { dir: staticRoot + "/assets" },
            "/css/*":    { dir: staticRoot + "/css" },
            "/images/*": { dir: staticRoot + "/images" },
            "/favicon.svg": Bun.file(staticRoot + "/favicon.svg"),
          },
          fetch: makeFetch(handler),
        });
      };
    };
  };
}

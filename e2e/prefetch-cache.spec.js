// Prefetch / cache behaviour: measured, not assumed.
//
// This file exists because reasoning about these headers predicted the wrong
// answer twice. Every assertion here was arrived at by running a real browser
// and reading CDP's fromDiskCache / fromPrefetchCache, which the Playwright
// request API does not expose.
//
// Current policy: successful full pages are `private, max-age=10` (CSP
// nonce); successful Datastar patches are `private, max-age=180` plus a
// strong ETag (quoted wyhash of the SSE bytes); errors are `no-store`;
// redirects derive their policy from the closed RedirectKind set.
//   * Full pages use `private` because they embed a per-request CSP nonce - a
//     shared cache would replay one visitor's nonce to everyone else.
//   * Patches contain no nonce, so they can live longer than a full page.
//     `private` is the sharing rule: a stale patch cannot leak across visitors
//     or a CDN. `max-age=180` is a separate product choice: long enough for
//     hover/click/popstate reuse inside a short session, short enough that a
//     deploy's stale copy dies in minutes. ETag is the revalidation half
//     after that window.
//   * `max-age` because without a freshness lifetime the response is explicit
//     but never fresh, with no validator to revalidate against, so nothing is
//     reused and the hover prefetch becomes pure overhead.
//
// If you change the cache policy, these tests fail. That is deliberate: the
// change should be a visible decision, not a silent behaviour shift.
import { test, expect } from "@playwright/test";
import { extractDatastarPatch } from "./support/sse.js";

// TARGET was /en/posts, the data-backed route, until the clean-sheet rebuild
// removed it (see .scratch/clean-sheet-homepage/) -- no data-backed exemplar
// exists in the tree right now (see CLAUDE.md). Guarantees stands in as an
// ordinary static route; the cache-policy assertions below don't depend on
// static vs. data-backed, only on "a second full page distinct from About".
const TARGET = "/en/guarantees";

test("HTML responses are private and carry no validators (W6)", async ({
  request,
}) => {
  // Deterministic — no browser cache involved.
  //
  // These are successful full pages, so `private` prevents a shared cache from
  // replaying one visitor's per-request CSP nonce. `max-age` is required because
  // without a freshness lifetime the response is explicit but never fresh, with
  // no validator to revalidate against — so nothing is reused and the hover
  // prefetch becomes pure overhead. No ETag/Last-Modified is emitted; the
  // max-age is the whole freshness story.
  // See App.Server.htmlCacheControl.
  for (const path of ["/en", "/en/about", TARGET]) {
    const res = await request.get(path);
    expect(res.status()).toBe(200);
    const h = res.headers();
    expect(h["cache-control"], `${path} cache-control`).toBe(
      "private, max-age=10",
    );
    expect(h["etag"], `${path} etag`).toBeUndefined();
    expect(h["last-modified"], `${path} last-modified`).toBeUndefined();
    expect(h["expires"], `${path} expires`).toBeUndefined();
  }
});

test("public documents are shared-cacheable", async ({ request }) => {
  // robots.txt and sitemap.xml are static files with long public cache.
  for (const path of ["/robots.txt", "/sitemap.xml"]) {
    const res = await request.get(path);
    expect(res.status()).toBe(200);
    expect(res.headers()["cache-control"], `${path}`).toBe(
      "public, max-age=86400",
    );
  }
});

test("static assets DO carry validators (Bun routes:{dir} supplies them)", async ({
  request,
}) => {
  // The contrast that shows the HTML asymmetry is accidental, not policy.
  const res = await request.get("/css/styles.css");
  expect(res.status()).toBe(200);
  const h = res.headers();
  expect(h["etag"] ?? h["last-modified"]).toBeTruthy();
});

test("patch signal matrix — header present or absent (W2)", async ({
  request,
}) => {
  // isDatastarRequest is a single signal (the datastar-request header),
  // unlike Alpine's old isFragmentRequest boolean-OR over a header AND a
  // ?_frag=1 query param. Datastar's own protocol has no header-free
  // query-param convention -- ADR-015 explicitly declined to invent one, so
  // there are only two cases here, not four.
  // Asserts the full response, not just body shape: status, Content-Type,
  // and Vary are part of the contract, not just the SSE-unwrapped body.
  // Covers BOTH /en/about and TARGET, the route the click test below
  // navigates to.
  const fetchCase = async (path, withHeader) =>
    request.get(path, withHeader ? { headers: { "datastar-request": "true" } } : {});

  const cases = [];
  for (const path of ["/en/about", TARGET]) {
    cases.push(
      { name: `${path} header present`, res: await fetchCase(path, true), patch: true },
      { name: `${path} header absent`, res: await fetchCase(path, false), patch: false },
    );
  }

  for (const c of cases) {
    const raw = await c.res.text();
    const h = c.res.headers();
    expect(c.res.status(), `${c.name}: status`).toBe(200);
    expect(h["cache-control"], `${c.name}: success cache policy`).toBe(
      c.patch ? "private, max-age=180" : "private, max-age=10",
    );
    if (c.patch) {
      expect(h["content-type"], `${c.name}: content-type`).toContain("text/event-stream");
      expect(h["vary"], `${c.name}: must vary on the datastar header`).toContain(
        "datastar-request",
      );
      expect(h["etag"], `${c.name}: patch ETag`).toBeTruthy();
      expect(raw).toContain("event: datastar-patch-elements");
      const body = extractDatastarPatch(raw);
      expect(body, `${c.name}: is a datastar-patch-elements event`).toBeTruthy();
      expect(body.includes('id="content"'), `${c.name}: carries the swap target`).toBe(true);
      expect(body).toContain('data-page-title');
      expect(body).toContain('data-template="site-header"');
      expect(body).not.toContain("<script");
      expect(body).not.toContain("<!DOCTYPE");
      expect(body).not.toContain("<html");
    } else {
      expect(h["content-type"], `${c.name}: content-type`).toContain("text/html");
      expect(raw.includes("<!DOCTYPE"), `${c.name}: full document`).toBe(true);
      expect(raw.includes("<html"), `${c.name}: full document`).toBe(true);
      expect(raw.includes('id="content"'), `${c.name}: carries the swap target`).toBe(true);
    }
  }
});

test("a matching If-None-Match on a patch is 304", async ({ request }) => {
  const first = await request.get("/en/about", {
    headers: { "datastar-request": "true" },
  });
  expect(first.status()).toBe(200);
  const etag = first.headers()["etag"];
  expect(etag, "successful patch must advertise an ETag").toBeTruthy();
  const again = await request.get("/en/about", {
    headers: { "datastar-request": "true", "if-none-match": etag },
  });
  expect(again.status()).toBe(304);
  expect(again.headers()["etag"]).toBe(etag);
});

test("the emitted Cache-Control survives the Bun bridge", async ({
  request,
}) => {
  // The ContractSpec assertion models the bridge (tuple ordering + Headers.set).
  // This exercises it: the header below is what the bridge actually emitted, so
  // a bridge change breaks this even if the unit-level model stays green.
  const err = await request.get("/en/definitely-not-a-route");
  expect(err.headers()["cache-control"], "error through the bridge").toBe(
    "no-store",
  );
  const ok = await request.get("/en/about");
  expect(ok.headers()["cache-control"], "success through the bridge").toBe(
    "private, max-age=10",
  );
  const red = await request.get("/", { maxRedirects: 0 });
  expect(red.status(), "root redirect").toBe(302);
  expect(red.headers()["cache-control"], "redirect through the bridge").toBe(
    "no-store",
  );
});

test("error responses are never stored", async ({ request }) => {
  // A transient 502 cached for ten seconds would answer a retry from cache,
  // which defeats the point of retrying. See App.Server.errorCacheControl.
  const res = await request.get("/en/definitely-not-a-route");
  expect(res.status()).toBe(404);
  expect(res.headers()["cache-control"]).toBe("no-store");
});

test("a datastar-request for an unknown route gets a patch, not a document", async ({
  request,
}) => {
  // The route-miss path runs before any Route exists, so it needs its own
  // coverage separate from a known route's error path — a Datastar request
  // to an unknown URL used to (pre-Datastar, with Alpine) risk swapping a
  // whole <!DOCTYPE> document into #content.
  const res = await request.get("/en/definitely-not-a-route", {
    headers: { "datastar-request": "true" },
  });
  // Always 200, not 404 — Datastar's client only applies a patch when
  // status === 200 (see ADR-015); the "not found"-ness is in the content.
  expect(res.status()).toBe(200);
  expect(res.headers()["cache-control"]).toBe("no-store");
  const raw = await res.text();
  expect(raw).toContain("event: datastar-patch-elements");
  const body = extractDatastarPatch(raw);
  expect(body).not.toContain("<!DOCTYPE");
  expect(body).not.toContain("<html");
  expect(body).toContain('id="content"');
});

test("a normal request for an unknown route still gets a full document", async ({
  request,
}) => {
  // The fragment fix must not degrade the ordinary 404.
  const res = await request.get("/en/definitely-not-a-route");
  const body = await res.text();
  expect(body).toContain("<!DOCTYPE");
  expect(body).toContain("<html");
});

test("the click is served from cache, not the network", async ({
  page,
  context,
}) => {
  const cdp = await context.newCDPSession(page);
  await cdp.send("Network.enable");

  // One event stream, keyed by CDP requestId. The previous version captured
  // bodies through a separate page.on('response') handler and matched cache
  // provenance to bodies by COUNT, which is cardinality within a phase, not
  // identity. requestId ties each observed click response to its cache
  // provenance; body shape is asserted separately by the fragment matrix.
  // Track method by requestId — Network.responseReceived does not carry it, and
  // treating every same-URL response as a click navigation would let a future
  // POST or subrequest contaminate the cardinality assertion.
  const methodOf = new Map();
  const clickRequestIds = new Set();
  let clickPhase = false;
  cdp.on("Network.requestWillBeSent", (e) => {
    methodOf.set(e.requestId, e.request.method);
    if (
      clickPhase &&
      e.request.method === "GET" &&
      e.request.url.includes(TARGET)
    ) {
      clickRequestIds.add(e.requestId);
    }
  });

  const seen = [];
  cdp.on("Network.responseReceived", (e) => {
    if (
      e.response.url.includes(TARGET) &&
      methodOf.get(e.requestId) === "GET"
    ) {
      seen.push({
        requestId: e.requestId,
        url: e.response.url,
        status: e.response.status,
        fromDiskCache: e.response.fromDiskCache === true,
        fromPrefetchCache: e.response.fromPrefetchCache === true,
      });
    }
  });

  await page.goto("/en");
  const link = page.locator(`header a[href="${TARGET}"]`).first();

  await link.hover();
  await page.waitForTimeout(1000);
  const afterHover = seen.length;

  clickPhase = true;
  await link.click();
  await page.waitForSelector("main");
  await page.waitForTimeout(1000);

  const cached = seen.filter((r) => r.fromDiskCache || r.fromPrefetchCache);

  // Surfaced in the run log so the numbers are visible, not just the verdict.
  console.log(
    `[prefetch-cache] responses during hover=${afterHover} ` +
      `total=${seen.length} servedFromCache=${cached.length}`,
  );
  seen.forEach((r, i) => {
    const phase = clickRequestIds.has(r.requestId) ? "click" : "load+hover";
    console.log(
      `[prefetch-cache]   #${i} (${phase}) ${r.status} ${r.url} ` +
        `disk=${r.fromDiskCache} prefetch=${r.fromPrefetchCache}`,
    );
  });

  // The hover must actually issue a request — otherwise this test proves nothing.
  expect(afterHover, "hover should trigger a prefetch request").toBeGreaterThan(
    0,
  );

  const clickResponses = seen.filter((r) => clickRequestIds.has(r.requestId));

  // W6 outcome, asserted on the CLICK specifically.
  //
  // Hover, click, and popstate all fetch `?datastar={}`: `@get(url, {payload: {}})`
  // and `dsPrefetchHover` both set that empty payload, so chrome `_` signals
  // cannot bust the cache key. See ADR-015.
  const clickFromCache = clickResponses.filter(
    (r) => r.fromDiskCache || r.fromPrefetchCache,
  );
  expect(
    clickFromCache.length,
    "Every click response must come from cache — not merely some response in " +
      "the trace. If this fails, dsPrefetchHover's signals-matching broke; see " +
      "App.Datastar.dsPrefetchHover and ADR-015.",
  ).toBe(clickResponses.length);

  // The post-swap re-fire (a THIRD request, prefetching the page already on
  // screen) is still fixed: after the patch re-renders the header, the new
  // link for the current route lands under the stationary cursor, mouseenter
  // fires again, but dsNavLinkRecord omits hover prefetch when the target is
  // the current route. What remains is exactly one response — the click's
  // own navigation, over the network per the assertion above.
  expect(
    clickResponses.length,
    "A click should cost exactly one response — the navigation. More than that " +
      "means a link is prefetching the route it already points at; see " +
      "dsNavLinkRecord's target === current guard in App.Datastar.",
  ).toBe(1);

  // Body shape is covered by the fragment signal-matrix test above. Do not call
  // Network.getResponseBody here: a valid cache-served response may have no
  // retrievable CDP body. This test owns request identity, method, status, URL,
  // and cache origin; the matrix owns raw response shape.
  for (const r of clickResponses) {
    expect(methodOf.get(r.requestId), "the click navigation must be GET").toBe(
      "GET",
    );
    expect(r.status, "the click response should be a 200").toBe(200);
    expect(r.url, "the correlated response must be the target URL").toContain(
      TARGET,
    );
  }
  expect(
    await page.locator("#content").count(),
    "exactly one swap target",
  ).toBe(1);
});

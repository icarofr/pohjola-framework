// Prefetch / cache behaviour: measured, not assumed.
//
// This file exists because reasoning about these headers predicted the wrong
// answer twice. Every assertion here was arrived at by running a real browser
// and reading CDP's fromDiskCache / fromPrefetchCache, which the Playwright
// request API does not expose. See RECONCILIATION.md (appendix + W6).
//
// Current policy: successful full pages and AJAX fragments are
// `private, max-age=10`; errors are `no-store`, and redirects derive their
// policy from the closed RedirectKind set.
//   * Full pages use `private` because they embed a per-request CSP nonce - a
//     shared cache would replay one visitor's nonce to everyone else.
//   * Fragments contain no nonce, but retain `private` as the conservative
//     browser-cache policy.
//   * `max-age` because without a freshness lifetime the response is explicit
//     but never fresh, with no validator to revalidate against, so nothing is
//     reused and the hover prefetch becomes pure overhead.
//
// If you change the cache policy, these tests fail. That is deliberate: the
// change should be a visible decision, not a silent behaviour shift.
import { test, expect } from '@playwright/test'

const TARGET = '/en/posts';

test('HTML responses are private and carry no validators (W6)', async ({ request }) => {
  // Deterministic — no browser cache involved.
  //
  // These are successful full pages, so `private` prevents a shared cache from
  // replaying one visitor's per-request CSP nonce. `max-age` is required because
  // without a freshness lifetime the response is explicit but never fresh, with
  // no validator to revalidate against — so nothing is reused and the hover
  // prefetch becomes pure overhead. No ETag/Last-Modified is emitted; the
  // max-age is the whole freshness story.
  // See App.Server.htmlCacheControl and RECONCILIATION.md "W6 outcome".
  for (const path of ['/en', '/en/about', '/en/posts', '/en/posts/1']) {
    const res = await request.get(path);
    expect(res.status()).toBe(200);
    const h = res.headers();
    expect(h['cache-control'], `${path} cache-control`).toBe('private, max-age=10');
    expect(h['etag'], `${path} etag`).toBeUndefined();
    expect(h['last-modified'], `${path} last-modified`).toBeUndefined();
    expect(h['expires'], `${path} expires`).toBeUndefined();
  }
});

test('the streamed route varies on the Alpine header like every other page', async ({ request }) => {
  // /en/posts is the streamed route. It was the one HTML response missing Vary,
  // so a cache could serve this full document to a request that asked for a
  // fragment — the two differ only by that request header.
  const res = await request.get('/en/posts');
  expect(res.headers()['vary']).toContain('x-alpine-request');
});

test('public documents are not marked private', async ({ request }) => {
  // robots.txt and sitemap.xml carry no nonce and should stay shared-cacheable.
  for (const path of ['/robots.txt', '/sitemap.xml']) {
    const res = await request.get(path);
    expect(res.status()).toBe(200);
    expect(res.headers()['cache-control'], `${path}`).toBeUndefined();
  }
});

test('static assets DO carry validators (Bun routes:{dir} supplies them)', async ({ request }) => {
  // The contrast that shows the HTML asymmetry is accidental, not policy.
  const res = await request.get('/css/styles.css');
  expect(res.status()).toBe(200);
  const h = res.headers();
  expect(h['etag'] ?? h['last-modified']).toBeTruthy();
});


test('fragment signal matrix — header, query, both, neither (W2)', async ({ request }) => {
  // isFragmentRequest is a boolean OR over two signals with different
  // producers: Alpine sends the header, ?_frag=1 is header-free (curl,
  // integration tests, non-header clients). ADR-007 supports both
  // deliberately, so all four combinations need pinning — previously only
  // header-only and neither were covered.
  // Asserts the full response, not just body shape: an earlier version checked
  // only for <!DOCTYPE>/id="content" while the comment called it the fragment
  // protocol contract. Status, Content-Type and Vary are part of that contract.
  // Covers BOTH the static route and TARGET, the streamed route the click test
  // navigates to. Previously only /en/about was checked, so a fragment-shape
  // regression on /en/posts could pass the matrix AND the cache-provenance test
  // — the click test asserts provenance, not shape, and deliberately tolerates
  // an unavailable cached body. This closes that gap without making body
  // retrieval a cache-policy prerequisite: these are plain requests, no cache.
  const fetchCase = async (path, query, withHeader) =>
    request.get(`${path}${query}`, withHeader ? { headers: { 'x-alpine-request': 'true' } } : {});

  const cases = [];
  for (const path of ['/en/about', TARGET]) {
    cases.push(
      { name: `${path} header only`, res: await fetchCase(path, '', true), fragment: true },
      { name: `${path} query only`, res: await fetchCase(path, '?_frag=1', false), fragment: true },
      { name: `${path} both signals`, res: await fetchCase(path, '?_frag=1', true), fragment: true },
      { name: `${path} neither`, res: await fetchCase(path, '', false), fragment: false }
    );
  }

  for (const c of cases) {
    const body = await c.res.text();
    const h = c.res.headers();
    expect(c.res.status(), `${c.name}: status`).toBe(200);
    expect(h['content-type'], `${c.name}: content-type`).toContain('text/html');
    expect(h['vary'], `${c.name}: must vary on the fragment header`).toContain('x-alpine-request');
    expect(h['cache-control'], `${c.name}: success cache policy`).toBe('private, max-age=10');
    expect(body.includes('id="content"'), `${c.name}: carries the swap target`).toBe(true);
    expect(body.includes('<!DOCTYPE'), `${c.name}: document?`).toBe(!c.fragment);
    expect(body.includes('<html'), `${c.name}: document?`).toBe(!c.fragment);
  }
});

test('the emitted Cache-Control survives the Bun bridge', async ({ request }) => {
  // The ContractSpec assertion models the bridge (tuple ordering + Headers.set).
  // This exercises it: the header below is what the bridge actually emitted, so
  // a bridge change breaks this even if the unit-level model stays green.
  const err = await request.get('/en/definitely-not-a-route');
  expect(err.headers()['cache-control'], 'error through the bridge').toBe('no-store');
  const ok = await request.get('/en/about');
  expect(ok.headers()['cache-control'], 'success through the bridge').toBe('private, max-age=10');
  const red = await request.get('/', { maxRedirects: 0 });
  expect(red.status(), 'root redirect').toBe(302);
  expect(red.headers()['cache-control'], 'redirect through the bridge').toBe('no-store');
});

test('error responses are never stored', async ({ request }) => {
  // A transient 502 cached for ten seconds would answer a retry from cache,
  // which defeats the point of retrying. See App.Server.errorCacheControl.
  const res = await request.get('/en/definitely-not-a-route');
  expect(res.status()).toBe(404);
  expect(res.headers()['cache-control']).toBe('no-store');
});

test('a fragment request for an unknown route gets a fragment, not a document', async ({ request }) => {
  // The route-miss path runs before any Route exists, so it was never covered
  // by the handleFragment fix — an AJAX request to an unknown URL used to swap
  // a whole <!DOCTYPE> document into #content.
  const res = await request.get('/en/definitely-not-a-route', {
    headers: { 'x-alpine-request': 'true' },
  });
  expect(res.status()).toBe(404);
  const body = await res.text();
  expect(body).not.toContain('<!DOCTYPE');
  expect(body).not.toContain('<html');
  expect(body).toContain('id="content"');
});

test('a normal request for an unknown route still gets a full document', async ({ request }) => {
  // The fragment fix must not degrade the ordinary 404.
  const res = await request.get('/en/definitely-not-a-route');
  const body = await res.text();
  expect(body).toContain('<!DOCTYPE');
  expect(body).toContain('<html');
});

test('the click is served from cache, not the network', async ({ page, context }) => {
  const cdp = await context.newCDPSession(page);
  await cdp.send('Network.enable');

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
  cdp.on('Network.requestWillBeSent', (e) => {
    methodOf.set(e.requestId, e.request.method);
    if (clickPhase && e.request.method === 'GET' && e.request.url.includes(TARGET)) {
      clickRequestIds.add(e.requestId);
    }
  });

  const seen = [];
  cdp.on('Network.responseReceived', (e) => {
    if (e.response.url.includes(TARGET) && methodOf.get(e.requestId) === 'GET') {
      seen.push({
        requestId: e.requestId,
        url: e.response.url,
        status: e.response.status,
        fromDiskCache: e.response.fromDiskCache === true,
        fromPrefetchCache: e.response.fromPrefetchCache === true,
      });
    }
  });

  await page.goto('/en');
  const link = page.locator(`header a[href="${TARGET}"]`).first();

  await link.hover();
  await page.waitForTimeout(1000);
  const afterHover = seen.length;

  clickPhase = true;
  await link.click();
  await page.waitForSelector('main');
  await page.waitForTimeout(1000);

  const cached = seen.filter((r) => r.fromDiskCache || r.fromPrefetchCache);

  // Surfaced in the run log so the numbers are visible, not just the verdict.
  console.log(
    `[prefetch-cache] responses during hover=${afterHover} ` +
      `total=${seen.length} servedFromCache=${cached.length}`
  );
  seen.forEach((r, i) => {
    const phase = clickRequestIds.has(r.requestId) ? 'click' : 'load+hover';
    console.log(
      `[prefetch-cache]   #${i} (${phase}) ${r.status} ${r.url} ` +
        `disk=${r.fromDiskCache} prefetch=${r.fromPrefetchCache}`
    );
  });

  // The hover must actually issue a request — otherwise this test proves nothing.
  expect(afterHover, 'hover should trigger a prefetch request').toBeGreaterThan(0);

  const clickResponses = seen.filter((r) => clickRequestIds.has(r.requestId));

  // W6 outcome, asserted on the CLICK specifically.
  //
  // An earlier version checked `cached.length > 0` across every observed
  // response, which a cached *hover* would have satisfied while the click still
  // hit the network — a weaker check than the claim written beside it.
  //
  // Three measurements were needed to get here, because reasoning from the
  // response headers alone predicted the wrong answer twice:
  //
  //   no Cache-Control      hover reused from prefetch cache, click hit network
  //   private (no max-age)  nothing reused — explicit but never fresh, and no
  //                         validator to revalidate against
  //   private, max-age=10   click served from disk cache  <- current
  //
  // `private` is required for full-page responses because each embeds a
  // per-request CSP nonce, and a shared cache would replay one visitor's nonce
  // to everyone. Fragments retain it as a conservative browser-cache policy.
  // The max-age is what makes successful responses reusable by that visitor's
  // own browser within the hover-to-click window.
  const clickFromCache = clickResponses.filter(
    (r) => r.fromDiskCache || r.fromPrefetchCache
  );
  expect(
    clickFromCache.length,
    'Every click response must come from cache — not merely some response in ' +
      'the trace. If this fails the cache policy changed and hover prefetch is ' +
      'doing nothing; see App.Server.htmlCacheControl and RECONCILIATION.md W6.'
  ).toBe(clickResponses.length);

  // The post-swap re-fire is FIXED. It used to cost a third request: after the
  // AJAX swap re-rendered the header, the new link for the current route landed
  // under the stationary cursor, mouseenter fired again, and it prefetched the
  // page already on screen. `navLink` now omits hover prefetch when the target
  // is the current route.
  //
  // What remains is the click itself — and per the assertion above it is now
  // served from cache rather than the network.
  expect(
    clickResponses.length,
    'A click should cost exactly one response — the navigation. More than that ' +
      'means a link is prefetching the route it already points at; see the ' +
      'navLink self-target guard in App.Alpine.'
  ).toBe(1);

  // Body shape is covered by the fragment signal-matrix test above. Do not call
  // Network.getResponseBody here: a valid cache-served response may have no
  // retrievable CDP body. This test owns request identity, method, status, URL,
  // and cache origin; the matrix owns raw response shape.
  for (const r of clickResponses) {
    expect(methodOf.get(r.requestId), 'the click navigation must be GET').toBe('GET');
    expect(r.status, 'the click response should be a 200').toBe(200);
    expect(r.url, 'the correlated response must be the target URL').toContain(TARGET);
  }
  expect(await page.locator('#content').count(), 'exactly one swap target').toBe(1);
});

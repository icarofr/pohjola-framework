import { test, expect } from "@playwright/test";

// TARGET was /en/posts/1 (the data-backed route, to force a real render
// failure) until the clean-sheet rebuild removed Posts (see
// .scratch/clean-sheet-homepage/) -- no data-backed route exists in the tree
// to 500 from, so this repoints at the route-miss 404 path instead, which
// exercises the same claim this test actually cares about: a Datastar patch
// error response is the exact #content shell, never a wrapped document.
test("a Datastar patch request for an unknown route gets the exact fragment shell, not a wrapped document", async ({
  page,
}) => {
  const response = await page.request.get("/en/definitely-not-a-route", {
    headers: { "datastar-request": "true" },
  });
  // Always 200, never 404 -- confirmed against the vendored datastar.js
  // source: the client only applies an SSE patch when status === 200;
  // anything else is treated as an error/redirect branch and the patch is
  // never applied. The "404-ness" is communicated by the rendered content
  // (dsSiteErrorPage's own "404" text), not the HTTP status -- a real,
  // deliberate difference from Alpine AJAX's fragment path, which could and
  // did carry the real status code.
  expect(response.status()).toBe(200);

  const body = await response.text();
  expect(body).toContain("event: datastar-patch-elements");
  const marker = "data: elements ";
  const html = body.slice(body.indexOf(marker) + marker.length).split("\n\n")[0];

  const parsed = await page.evaluate(
    (h) => {
      const document = new DOMParser().parseFromString(h, "text/html");
      return {
        hasContent: Boolean(document.body.querySelector("div#content")),
        wrappers: document.body.querySelectorAll("html,body,script,link,style")
          .length,
      };
    },
    html,
  );

  expect(parsed.hasContent).toBe(true);
  expect(parsed.wrappers).toBe(0);
});

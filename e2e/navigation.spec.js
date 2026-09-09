import { test, expect } from "@playwright/test";
import { extractDatastarPatch } from "./support/sse.js";

test.describe("Datastar navigation", () => {
  test("initial response is a complete document with template page shell", async ({
    page,
  }) => {
    await page.goto("/en");
    await expect(page.locator('div#content[data-page-title]')).toBeVisible();
    await expect(
      page.locator('header[data-template="site-header"]'),
    ).toBeVisible();
    await expect(page.locator("div#content .drawer-content > main.flex-1")).toBeVisible();
    expect(
      await page.locator("div#content").evaluate((root) => {
        const drawerContent = root.querySelector(".drawer-content");
        return {
          hasDrawer: root.classList.contains("drawer"),
          headerInDrawer: Boolean(
            drawerContent?.querySelector('header[data-template="site-header"]'),
          ),
          mainInDrawer: Boolean(drawerContent?.querySelector("main.flex-1")),
          footerCount: root.querySelectorAll("footer").length,
        };
      }),
    ).toEqual({
      hasDrawer: true,
      headerInDrawer: true,
      mainInDrawer: true,
      footerCount: 1,
    });
    expect(await page.locator("html").count()).toBe(1);
    expect(await page.locator("script").count()).toBeGreaterThan(0);
  });

  test("clicking a nav link swaps content without reload", async ({ page }) => {
    await page.goto("/en");

    await expect(page.locator('div#content[data-page-title]')).toContainText(
      "A framework built to make AI-written code safer to ship",
    );

    await page.evaluate(() => {
      window.__marker = 1;
    });

    await page
      .locator('header nav.hidden.md\\:flex a[href="/en/about"]')
      .click();

    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page).toHaveTitle(/About/);
    await expect(page.locator('div#content[data-page-title]')).toContainText(
      "About Pohjola",
    );
    await expect(
      page.locator('header nav.hidden.md\\:flex a[href="/en/about"]'),
    ).toHaveCount(1);

    expect(await page.evaluate(() => window.__marker)).toBe(1);
  });

  test("clicking logo returns to home", async ({ page }) => {
    await page.goto("/en/about");

    await page.evaluate(() => {
      window.__marker = 1;
    });

    await page.click('header a[href="/en"]');
    await expect(page).toHaveURL(/\/en$/);
    expect(await page.evaluate(() => window.__marker)).toBe(1);
  });

  test("language switch swaps content without reload", async ({ page }) => {
    await page.goto("/en");

    await page.evaluate(() => {
      window.__marker = 1;
    });

    await page.getByLabel("Switch language").click();
    await page.locator("header a").filter({ hasText: /Français/i }).click();
    await expect(page).toHaveURL(/\/fr$/);
    await expect(page.locator("html")).toHaveAttribute("lang", "fr");
    await expect(page.locator("main")).toContainText(
      "Un framework conçu pour sécuriser le code écrit par l'IA",
    );

    expect(await page.evaluate(() => window.__marker)).toBe(1);
  });

  test("hero CTA button link navigation works without reload", async ({
    page,
  }) => {
    await page.goto("/en");

    await page.evaluate(() => {
      window.__marker = 1;
    });

    await page.locator('main a[href="/en/guarantees"]').first().click();

    await expect(page).toHaveURL(/\/en\/guarantees/);
    await expect(page).toHaveTitle(/Guarantees/);
    await expect(page.locator('div#content[data-page-title]')).toContainText(
      "Guarantees",
    );

    expect(await page.evaluate(() => window.__marker)).toBe(1);
  });

  test("two AJAX navigations then goBack works correctly without reload", async ({
    page,
  }) => {
    await page.goto("/en");

    await page.evaluate(() => {
      window.__marker = 1;
    });

    await page.click('a[href="/en/about"]');
    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page).toHaveTitle(/About/);

    await page.click('a[href="/en/guarantees"]');
    await expect(page).toHaveURL(/\/en\/guarantees/);
    await expect(page).toHaveTitle(/Guarantees/);
    await expect(page.locator('div#content[data-page-title]')).toContainText(
      "Guarantees",
    );
    const historyLength = await page.evaluate(() => history.length);

    await page.goBack();
    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page).toHaveTitle(/About/);
    await expect(page.locator('div#content[data-page-title]')).toContainText(
      "About Pohjola",
    );
    expect(await page.evaluate(() => window.__marker)).toBe(1);
    expect(await page.evaluate(() => history.length)).toBe(historyLength);

    await page.goBack();
    await expect(page).toHaveURL(/\/en$/);
    await expect(page).toHaveTitle(/Pohjola/);
    await expect(page.locator('div#content[data-page-title]')).toContainText(
      "A framework built to make AI-written code safer to ship",
    );
    expect(await page.evaluate(() => window.__marker)).toBe(1);
    expect(await page.evaluate(() => history.length)).toBe(historyLength);

    await page.goForward();
    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page).toHaveTitle(/About/);
    expect(await page.evaluate(() => window.__marker)).toBe(1);
    expect(await page.evaluate(() => history.length)).toBe(historyLength);
  });

  test("hover prefetch requests a patch, not a full page", async ({
    page,
  }) => {
    await page.goto("/en");

    let fragmentBody;
    // "**/en/about**" (not "**/en/about"): dsPrefetchHover now appends a
    // ?datastar={...} query param matching the real @get() URL (see
    // ADR-015's "hover-prefetch cache-hit" entry), so the intercepted URL
    // no longer ends exactly in "/en/about".
    await page.route("**/en/about**", async (route) => {
      const headers = route.request().headers();
      if (headers["datastar-request"] === "true") {
        const response = await route.fetch();
        fragmentBody = extractDatastarPatch(await response.text());
        await route.fulfill({ response });
      } else {
        await route.continue();
      }
    });

    await page.hover('header nav.hidden.md\\:flex a[href="/en/about"]');
    await page.waitForTimeout(500);

    expect(fragmentBody).toBeTruthy();
    expect(fragmentBody).not.toContain("<!DOCTYPE");
    expect(fragmentBody).toContain('id="content"');
    expect(fragmentBody).toContain("data-page-title");
    expect(fragmentBody).toContain('data-template="site-header"');
    expect(fragmentBody).not.toContain("<html");
    expect(fragmentBody).not.toContain("<script");
  });

  test("success and route-miss patches are template page shapes", async ({
    page,
  }) => {
    await page.goto("/en");
    for (const [path, expectOk] of [
      ["/en/about", true],
      ["/en/definitely-not-a-route", false],
    ]) {
      // Inlined, not imported: this callback is serialized to run inside the
      // BROWSER's JS realm (page.evaluate), which can't close over a Node-side
      // ES import -- see extractDatastarPatch above for the Node-side version
      // of the identical two-line logic.
      const result = await page.evaluate(async ([url, ok]) => {
        const marker = "data: elements ";
        const response = await fetch(url, {
          headers: { "datastar-request": "true" },
        });
        const body = await response.text();
        const html = body.slice(body.indexOf(marker) + marker.length).split("\n\n")[0];
        const parsed = new DOMParser().parseFromString(html, "text/html");
        return {
          // Always 200, even for the route-miss case -- Datastar's client
          // only applies a patch when status === 200 (see ADR-015); the
          // "not found"-ness is communicated by rendered content, not status.
          status: response.status,
          hasContent: Boolean(
            parsed.body.querySelector("div#content[data-page-title]"),
          ),
          hasHeader: Boolean(
            parsed.body.querySelector('header[data-template="site-header"]'),
          ),
          forbidden: parsed.body.querySelectorAll("html,body,script,link,style")
            .length,
          ok,
        };
      }, [path, expectOk]);
      expect(result.hasContent, path).toBe(true);
      expect(result.hasHeader, path).toBe(true);
      expect(result.forbidden, path).toBe(0);
      expect(result.status, path).toBe(200);
    }
  });

  test("scrolls to top on nav-link swap", async ({ page }) => {
    await page.goto("/en");
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await expect
      .poll(() => page.evaluate(() => window.scrollY))
      .toBeGreaterThan(0);

    await page
      .locator('header nav.hidden.md\\:flex a[href="/en/about"]')
      .click();

    await expect(page).toHaveURL(/\/en\/about/);
    expect(await page.evaluate(() => window.scrollY)).toBe(0);
  });

  test("scrolls to top on browser back (popstate restore)", async ({ page }) => {
    await page.goto("/en");
    await page.click('a[href="/en/about"]');
    await expect(page).toHaveURL(/\/en\/about/);

    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await expect
      .poll(() => page.evaluate(() => window.scrollY))
      .toBeGreaterThan(0);

    await page.goBack();
    await expect(page).toHaveURL(/\/en$/);
    expect(await page.evaluate(() => window.scrollY)).toBe(0);
  });

  test("404 patch keeps drawer chrome and data-page-title", async ({ page }) => {
    await page.goto("/en");
    // Inlined for the same reason as above: runs inside the browser realm.
    await page.evaluate(async () => {
      const marker = "data: elements ";
      const r = await fetch("/en/no-such-page", {
        headers: { "datastar-request": "true" },
      });
      const sse = await r.text();
      const h = sse.slice(sse.indexOf(marker) + marker.length).split("\n\n")[0];
      const d = new DOMParser().parseFromString(h, "text/html");
      const n = d.getElementById("content");
      const o = document.getElementById("content");
      if (!n || !o) throw new Error("missing #content");
      o.replaceWith(n);
    });
    await expect(page.locator("header[data-template='site-header']")).toBeVisible();
    await expect(page.locator("div#content[data-page-title]")).toBeVisible();
    expect(await page.locator("html").count()).toBe(1);
  });
});

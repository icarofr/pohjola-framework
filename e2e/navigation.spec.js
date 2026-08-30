import { test, expect } from "@playwright/test";

test.describe("Alpine AJAX navigation", () => {
  test("initial response is a complete document with synchronized shell", async ({
    page,
  }) => {
    await page.goto("/en");
    await expect(page.locator("header#header[x-sync]")).toBeVisible();
    await expect(page.locator("main#content[data-page-title]")).toBeVisible();
    expect(
      await page.locator("body").evaluate((body) => {
        const children = [...body.children];
        return {
          headerIndex: children.indexOf(body.querySelector("header#header")),
          mainIndex: children.indexOf(body.querySelector("main#content")),
          footerCount: body.querySelectorAll("footer").length,
          scriptCount: body.querySelectorAll("script").length,
        };
      }),
    ).toEqual({ headerIndex: 0, mainIndex: 1, footerCount: 1, scriptCount: 2 });
    expect(await page.locator("html").count()).toBe(1);
    expect(await page.locator("script").count()).toBeGreaterThan(0);
  });
  test("clicking a nav link swaps main content without reload", async ({
    page,
  }) => {
    await page.goto("/en");

    // Verify initial state
    await expect(page.locator("main#content[data-page-title]")).toContainText(
      "The Type-Safe Functional Web Framework",
    );

    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      window.__marker = 1;
    });

    // Click the desktop nav About link (not hero CTA or lang switcher).
    await page
      .locator('header#header .navbar-center a[href="/en/about"]')
      .click();

    // URL should update
    await expect(page).toHaveURL(/\/en\/about/);

    // Page title should update
    await expect(page).toHaveTitle(/About/);

    // Main content should contain the About heading
    await expect(page.locator("main#content[data-page-title]")).toContainText(
      "About",
    );
    await expect(page.locator("header#header[x-sync]")).toHaveCount(1);
    // Desktop navbar + mobile primary nav each render one About link. Language
    // switcher links also point at the current URL (/en/about) — scope to nav
    // regions, not href alone (mobile drawer utility footer reuses the URL).
    // Use href + region scoping, not getByRole: the mobile drawer is md:hidden
    // on desktop viewports, so role queries (visible-only) miss those links.
    await expect(
      page.locator('header#header .navbar-center a[href="/en/about"]'),
    ).toHaveCount(1);
    await expect(
      page.locator(
        'header#header .mobile-drawer > .space-y-1 a[href="/en/about"]',
      ),
    ).toHaveCount(1);

    // Marker should still be 1 (no reload occurred)
    expect(await page.evaluate(() => window.__marker)).toBe(1);
  });

  test("clicking logo returns to home", async ({ page }) => {
    await page.goto("/en/about");

    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      window.__marker = 1;
    });

    await page.click('a[href="/en"]');
    await expect(page).toHaveURL(/\/en$/);

    // Marker should still be 1 (no reload occurred)
    expect(await page.evaluate(() => window.__marker)).toBe(1);
  });

  test("language switch performs a full navigation", async ({ page }) => {
    await page.goto("/en");

    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      window.__marker = 1;
    });

    await page.getByRole("button", { name: /Switch language|Changer de langue/ }).click();
    await page
      .locator("#header-lang-menu")
      .getByRole("link", { name: /Français|French/i })
      .click();
    await expect(page).toHaveURL(/\/fr$/);
    await expect(page.locator("main")).toContainText(
      "Le framework web fonctionnel",
    );

    // Marker should be gone (full reload occurred)
    expect(await page.evaluate(() => window.__marker)).toBeUndefined();
  });

  test("hero CTA button link navigation works without reload", async ({
    page,
  }) => {
    await page.goto("/en");

    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      window.__marker = 1;
    });

    // The hero CTA is inside main, not the header navigation.
    await page.locator('main a[href="/en/about"]').first().click();

    // URL should update
    await expect(page).toHaveURL(/\/en\/about/);

    // Title should update
    await expect(page).toHaveTitle(/About/);
    await expect(page.locator("header#header[x-sync]")).toHaveCount(1);

    // Content should show the About page targeted by the hero CTA
    await expect(page.locator("main#content[data-page-title]")).toContainText(
      "About",
    );

    // Marker should still be 1 (no reload occurred)
    expect(await page.evaluate(() => window.__marker)).toBe(1);
  });

  test("two AJAX navigations then goBack works correctly without reload", async ({
    page,
  }) => {
    await page.goto("/en");

    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      window.__marker = 1;
    });

    // Navigate to About
    await page.click('a[href="/en/about"]');
    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page).toHaveTitle(/About/);
    await expect(page.locator("header#header[x-sync]")).toHaveCount(1);

    // Navigate to Contact
    await page.click('a[href="/en/contact"]');
    await expect(page).toHaveURL(/\/en\/contact/);
    await expect(page).toHaveTitle(/Contact/);
    await expect(page.locator("main#content[data-page-title]")).toContainText(
      "Contact",
    );
    const historyLength = await page.evaluate(() => history.length);

    // Go back to About — seamless SPA fragment swap (marker preserved!)
    await page.goBack();
    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page).toHaveTitle(/About/);
    await expect(page.locator("main#content[data-page-title]")).toContainText(
      "About",
    );
    expect(await page.evaluate(() => window.__marker)).toBe(1);
    await expect(page.locator("header#header[x-sync]")).toHaveCount(1);
    expect(await page.evaluate(() => history.length)).toBe(historyLength);

    // Go back to Home — seamless SPA fragment swap (marker preserved!)
    await page.goBack();
    await expect(page).toHaveURL(/\/en$/);
    await expect(page).toHaveTitle(/Pohjola/);
    await expect(page.locator("main#content[data-page-title]")).toContainText(
      "The Type-Safe Functional Web Framework",
    );
    expect(await page.evaluate(() => window.__marker)).toBe(1);
    await expect(page.locator("header#header[x-sync]")).toHaveCount(1);
    expect(await page.evaluate(() => history.length)).toBe(historyLength);

    // Go forward to About
    await page.goForward();
    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page).toHaveTitle(/About/);
    expect(await page.evaluate(() => window.__marker)).toBe(1);
    await expect(page.locator("header#header[x-sync]")).toHaveCount(1);
    expect(await page.evaluate(() => history.length)).toBe(historyLength);
  });

  test("hover prefetch requests a fragment, not a full page", async ({
    page,
  }) => {
    await page.goto("/en");

    // Intercept the mouseenter fetch response via route interception
    let fragmentBody;
    await page.route("**/en/about", async (route) => {
      const headers = route.request().headers();
      if (headers["x-alpine-request"] === "true") {
        // Let it go to the server and capture the response
        const response = await route.fetch();
        fragmentBody = await response.text();
        await route.fulfill({ response });
      } else {
        await route.continue();
      }
    });

    // Hover over the About nav link — triggers @mouseenter prefetch
    await page.hover('header#header a[href="/en/about"]');
    await page.waitForTimeout(500);

    // The mouseenter fetch should have been intercepted
    expect(fragmentBody).toBeTruthy();

    // The response should be a fragment (no <!DOCTYPE html>)
    expect(fragmentBody).not.toContain("<!DOCTYPE");
    expect(fragmentBody).toContain('<header id="header"');
    expect(fragmentBody).toContain("x-sync");
    expect(fragmentBody).toContain('<main id="content"');
    expect(fragmentBody).not.toContain("<html");
    expect(fragmentBody).not.toContain("<script");
  });

  test("success, route-miss, and error fragments have only shell children", async ({
    page,
  }) => {
    await page.goto("/en");
    for (const path of ["/en/about", "/en/definitely-not-a-route"]) {
      const result = await page.evaluate(async (url) => {
        const response = await fetch(url, {
          headers: { "x-alpine-request": "true" },
        });
        const parsed = new DOMParser().parseFromString(
          await response.text(),
          "text/html",
        );
        return {
          status: response.status,
          children: [...parsed.body.children].map((node) => ({
            name: `${node.tagName.toLowerCase()}#${node.id}`,
            sync: node.getAttribute("x-sync"),
            title: node.getAttribute("data-page-title"),
          })),
          forbidden: parsed.body.querySelectorAll("html,body,script,link,style")
            .length,
        };
      }, path);
      expect(result.children, path).toEqual([
        { name: "header#header", sync: "", title: null },
        { name: "main#content", sync: null, title: expect.any(String) },
      ]);
      expect(result.forbidden, path).toBe(0);
      expect(result.status, path).toBe(path.includes("definitely") ? 404 : 200);
    }
  });
});

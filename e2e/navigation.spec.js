import { test, expect } from "@playwright/test";

test.describe("Alpine AJAX navigation", () => {
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
      "The Type-Safe Functional Web Framework",
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

    await page.locator('header a[href="/fr"]').filter({ hasText: /Français/i }).click();
    await expect(page).toHaveURL(/\/fr$/);
    await expect(page.locator("html")).toHaveAttribute("lang", "fr");
    await expect(page.locator("main")).toContainText(
      "Le framework web fonctionnel",
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

    await page.locator('main a[href="/en/about"]').first().click();

    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page).toHaveTitle(/About/);
    await expect(page.locator('div#content[data-page-title]')).toContainText(
      "About Pohjola",
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

    await page.click('a[href="/en/contact"]');
    await expect(page).toHaveURL(/\/en\/contact/);
    await expect(page).toHaveTitle(/Contact/);
    await expect(page.locator('div#content[data-page-title]')).toContainText(
      "Community & Contributing",
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
      "The Type-Safe Functional Web Framework",
    );
    expect(await page.evaluate(() => window.__marker)).toBe(1);
    expect(await page.evaluate(() => history.length)).toBe(historyLength);

    await page.goForward();
    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page).toHaveTitle(/About/);
    expect(await page.evaluate(() => window.__marker)).toBe(1);
    expect(await page.evaluate(() => history.length)).toBe(historyLength);
  });

  test("hover prefetch requests a fragment, not a full page", async ({
    page,
  }) => {
    await page.goto("/en");

    let fragmentBody;
    await page.route("**/en/about", async (route) => {
      const headers = route.request().headers();
      if (headers["x-alpine-request"] === "true") {
        const response = await route.fetch();
        fragmentBody = await response.text();
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

  test("success and route-miss fragments are template page shapes", async ({
    page,
  }) => {
    await page.goto("/en");
    for (const [path, expectTemplate] of [
      ["/en/about", true],
      ["/en/definitely-not-a-route", false],
    ]) {
      const result = await page.evaluate(async ([url, template]) => {
        const response = await fetch(url, {
          headers: { "x-alpine-request": "true" },
        });
        const parsed = new DOMParser().parseFromString(
          await response.text(),
          "text/html",
        );
        return {
          status: response.status,
          hasContent: Boolean(
            parsed.body.querySelector("div#content[data-page-title]"),
          ),
          hasHeader: Boolean(
            parsed.body.querySelector('header[data-template="site-header"]'),
          ),
          forbidden: parsed.body.querySelectorAll("html,body,script,link,style")
            .length,
          template,
        };
      }, [path, expectTemplate]);
      expect(result.hasContent, path).toBe(expectTemplate);
      if (expectTemplate) {
        expect(result.hasHeader, path).toBe(true);
      }
      expect(result.forbidden, path).toBe(0);
      expect(result.status, path).toBe(expectTemplate ? 200 : 404);
    }
  });
});

import { test, expect } from "@playwright/test";

async function chooseFrench(page) {
  await page.getByLabel("Switch language").click();
  await page
    .locator("header a")
    .filter({ hasText: /Français/i })
    .click();
}

test.describe("Internationalization", () => {
  test("French language detection works", async ({ browser }) => {
    const context = await browser.newContext({ locale: "fr-FR" });
    const page = await context.newPage();
    await page.goto("/");

    await expect(page).toHaveURL(/\/fr$/);
    await expect(page.locator("main")).toContainText(
      "Un framework construit sur des garanties, pas des conventions",
    );
    await expect(page.locator("html")).toHaveAttribute("lang", "fr");
    await context.close();
  });

  test("language link flips HTML lang attribute", async ({ page }) => {
    await page.goto("/en");
    await expect(page.locator("html")).toHaveAttribute("lang", "en");

    await chooseFrench(page);
    await expect(page).toHaveURL(/\/fr$/);
    await expect(page.locator("html")).toHaveAttribute("lang", "fr");
  });

  test("language switch avoids full page reload", async ({ page }) => {
    await page.goto("/en/about");
    await page.evaluate(() => {
      window.__spaMarker = true;
    });

    await chooseFrench(page);

    await expect(page).toHaveURL(/\/fr\/about$/);
    await expect(page.locator("html")).toHaveAttribute("lang", "fr");
    await expect(
      page.evaluate(() => window.__spaMarker === true),
    ).resolves.toBe(true);
    await expect(page.locator("main")).toContainText("À propos de Pohjola");
  });

  test("language switch syncs title and lang only", async ({ page }) => {
    // Patch navigation (dsLangLink -> @get + SSE patch) only syncs
    // document.title and <html lang> client-side -- the only two fields
    // with a real client-side observer (browser tab; screen-reader
    // pronunciation). SEO/social metadata (description, OG, hreflang) is
    // correct in the server-rendered <head> on every direct request, and
    // crawlers/unfurlers never execute this client script, so it's
    // intentionally not synced here -- see App.Datastar's
    // dataPageTitleAttr/dataPageLangAttr doc.
    await page.goto("/en/about");
    await expect(page).toHaveTitle(/About/);

    await chooseFrench(page);

    await expect(page).toHaveURL(/\/fr\/about$/);
    await expect(page).toHaveTitle(/À propos/);
    await expect(page.locator("html")).toHaveAttribute("lang", "fr");
  });

  test("mobile drawer menu opens and closes", async ({ page }) => {
    await page.goto("/en");
    await page.setViewportSize({ width: 375, height: 667 });

    const drawerToggle = page.locator("#site-drawer");
    const menuButton = page.getByLabel("Open menu");
    await expect(drawerToggle).not.toBeChecked();

    await menuButton.click();
    await expect(drawerToggle).toBeChecked();
    await expect(page.locator(".drawer-side .menu")).toBeVisible();

    await page.getByLabel("Close menu").click();
    await expect(drawerToggle).not.toBeChecked();
  });
});

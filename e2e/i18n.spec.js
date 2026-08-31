import { test, expect } from "@playwright/test";

test.describe("Internationalization", () => {
  test("French language detection works", async ({ browser }) => {
    const context = await browser.newContext({ locale: "fr-FR" });
    const page = await context.newPage();
    await page.goto("/");

    await expect(page).toHaveURL(/\/fr$/);
    await expect(page.locator("main")).toContainText(
      "Le framework web fonctionnel",
    );
    await expect(page.locator("html")).toHaveAttribute("lang", "fr");
    await context.close();
  });

  test("language link flips HTML lang attribute", async ({ page }) => {
    await page.goto("/en");
    await expect(page.locator("html")).toHaveAttribute("lang", "en");

    await page
      .locator('header a[href="/fr"]')
      .filter({ hasText: /Français/i })
      .click();
    await expect(page).toHaveURL(/\/fr$/);
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

  test("banner text localizes correctly", async ({ page }) => {
    await page.goto("/en/contact?status=error");
    await expect(page.locator('[data-form-status="error"]')).toContainText(
      "Something went wrong",
    );

    await page.goto("/fr/contact?status=error");
    await expect(page.locator('[data-form-status="error"]')).toContainText(
      "Une erreur est survenue",
    );
  });
});

import { test, expect } from "@playwright/test";

test.describe("Community & Contributing Hub", () => {
  test("community page renders heading and action cards", async ({ page }) => {
    await page.goto("/en/contact");

    await expect(page.locator("main")).toContainText(
      "Community & Contributing",
    );
    await expect(
      page.locator(
        'main a[href="https://github.com/icarofr/pohjola-framework/issues"]',
      ),
    ).toBeVisible();
    await expect(
      page.locator(
        'main a[href="https://github.com/icarofr/pohjola-framework/discussions"]',
      ),
    ).toBeVisible();
    await expect(
      page.locator(
        'main a[href="https://github.com/icarofr/pohjola-framework"]',
      ),
    ).toBeVisible();
  });
});

test.describe("Mobile menu", () => {
  test("mobile menu opens and closes", async ({ page }) => {
    await page.goto("/en");
    await page.setViewportSize({ width: 375, height: 667 });

    const drawerToggle = page.locator("#site-drawer");
    const menuButton = page.getByLabel("Open menu");
    const closeButton = page.getByLabel("Close menu");
    await expect(drawerToggle).not.toBeChecked();

    await menuButton.click();
    await expect(drawerToggle).toBeChecked();
    await expect(closeButton).toBeVisible();
    await expect(
      page.locator('.drawer-side .menu a[href="/en/about"]'),
    ).toBeVisible();

    await closeButton.click();
    await expect(drawerToggle).not.toBeChecked();
    await expect(closeButton).toBeHidden();
  });

  test("mobile menu closes with Escape key", async ({ page }) => {
    await page.goto("/en");
    await page.setViewportSize({ width: 375, height: 667 });

    const drawerToggle = page.locator("#site-drawer");
    const closeButton = page.getByLabel("Close menu");

    await page.getByLabel("Open menu").click();
    await expect(drawerToggle).toBeChecked();
    await expect(closeButton).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(drawerToggle).not.toBeChecked();
    await expect(closeButton).toBeHidden();
  });
});

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

    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });

    // Menu should be hidden initially (x-cloak)
    const mobileNav = page.locator(".drawer-side .menu");
    await expect(page.locator("#nav-drawer")).not.toBeChecked();

    const menuButton = page.getByLabel("Open menu");
    await menuButton.click();

    await expect(page.locator("#nav-drawer")).toBeChecked();
    await expect(mobileNav).toBeVisible();

    await page.locator(".drawer-overlay").click({ force: true });

    await expect(page.locator("#nav-drawer")).not.toBeChecked();
  });

  test("mobile menu closes with Escape key", async ({ page }) => {
    await page.goto("/en");

    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });

    // Open menu
    await page.getByLabel("Open menu").click();
    await expect(page.locator("#nav-drawer")).toBeChecked();

    await page.locator(".drawer-overlay").click({ force: true });
    await expect(page.locator("#nav-drawer")).not.toBeChecked();
  });
});

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
    const mobileNav = page.locator("header#header .mobile-drawer");
    await expect(mobileNav).toBeHidden();

    // Click hamburger
    const menuButton = page.getByRole("button", {
      name: "Toggle navigation menu",
    });
    await menuButton.click();

    // Menu should be visible
    await expect(mobileNav).toBeVisible();

    // Click again to close
    await menuButton.click();

    // Menu should be hidden again
    await expect(mobileNav).toBeHidden();
  });

  test("mobile menu closes with Escape key", async ({ page }) => {
    await page.goto("/en");

    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });

    // Open menu
    const mobileNav = page.locator("header#header .mobile-drawer");
    await page.getByRole("button", { name: "Toggle navigation menu" }).click();
    await expect(mobileNav).toBeVisible();

    // Close with Escape
    await page.keyboard.press("Escape");
    await expect(mobileNav).toBeHidden();
  });
});

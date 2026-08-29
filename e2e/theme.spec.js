import { test, expect } from "@playwright/test";

test.describe("Theme switcher (Light / Dark / System)", () => {
  test("desktop dropdown selects each theme", async ({ page }) => {
    await page.goto("/en");

    // Initial state: default system (no dark class in standard light mode test env)
    await expect(page.locator("html")).not.toHaveClass(/dark/);

    const dropdown = page.locator("header#header .dropdown").nth(1);
    const themeToggle = dropdown.getByRole("button", {
      name: /Select theme \(Light \/ Dark \/ System\)/,
    });
    await themeToggle.click();
    await dropdown.getByRole("button", { name: "Dark" }).click();
    await expect(page.locator("html")).toHaveClass(/dark/);
    expect(await page.evaluate(() => localStorage.getItem("theme"))).toBe(
      "dark",
    );
    await themeToggle.click();
    await dropdown.getByRole("button", { name: "Light" }).click();
    await expect(page.locator("html")).not.toHaveClass(/dark/);
    expect(await page.evaluate(() => localStorage.getItem("theme"))).toBe(
      "light",
    );
    await themeToggle.click();
    await dropdown.getByRole("button", { name: "System" }).click();
    expect(await page.evaluate(() => localStorage.getItem("theme"))).toBe(
      "system",
    );
  });

  test("dark mode persists on reload", async ({ page }) => {
    await page.goto("/en");

    const dropdown = page.locator("header#header .dropdown").nth(1);
    const themeToggle = dropdown.getByRole("button", {
      name: /Select theme \(Light \/ Dark \/ System\)/,
    });
    await themeToggle.click();
    await dropdown.getByRole("button", { name: "Dark" }).click();
    await expect(page.locator("html")).toHaveClass(/dark/);

    // Reload — dark mode should persist via localStorage
    await page.reload();
    await expect(page.locator("html")).toHaveClass(/dark/);
  });

  test("dark mode survives AJAX nav", async ({ page }) => {
    await page.goto("/en");

    const dropdown = page.locator("header#header .dropdown").nth(1);
    const themeToggle = dropdown.getByRole("button", {
      name: /Select theme \(Light \/ Dark \/ System\)/,
    });
    await themeToggle.click();
    await dropdown.getByRole("button", { name: "Dark" }).click();
    await expect(page.locator("html")).toHaveClass(/dark/);

    // Navigate via AJAX
    await page.click('a[href="/en/about"]');
    await expect(page).toHaveURL(/\/en\/about/);

    // Dark mode should still be present
    await expect(page.locator("html")).toHaveClass(/dark/);
  });

  test("clicking theme switcher in mobile menu changes theme without closing the menu", async ({
    page,
  }) => {
    await page.goto("/en");
    await page.setViewportSize({ width: 375, height: 667 });

    // Open mobile menu
    await page.getByRole("button", { name: "Toggle navigation menu" }).click();
    const mobileMenu = page.locator("header#header .mobile-drawer");
    await expect(mobileMenu).toBeVisible();

    // Click the theme switcher inside the mobile menu
    const mobileThemeToggle = mobileMenu
      .getByRole("button", { name: /^(Light|Dark|System)$/ })
      .first();
    await mobileMenu.getByRole("button", { name: "Dark" }).click();

    // Mobile menu must still be visible
    await expect(mobileMenu).toBeVisible();

    await expect(mobileMenu).toBeVisible();
    await expect(page.locator("html")).toHaveClass(/dark/);
  });
});

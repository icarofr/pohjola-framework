import { test, expect } from "@playwright/test";

test.describe("Theme switcher (Light / Dark / System)", () => {
  async function openDesktopThemeMenu(page) {
    const themeMenu = page.locator("#header-theme-menu");
    const themeToggle = page.getByRole("button", {
      name: /Select theme|Sélectionner le thème/,
    });
    if (!(await themeMenu.isVisible())) {
      await themeToggle.click();
    }
    return { themeMenu, themeToggle };
  }

  test("desktop dropdowns close on click outside", async ({ page }) => {
    await page.goto("/en");
    const langMenu = page.locator("#header-lang-menu");
    const themeMenu = page.locator("#header-theme-menu");
    const outside = page.locator("main h1").first();

    await page.getByRole("button", { name: /Switch language|Changer de langue/ }).click();
    await expect(langMenu).toBeVisible();
    await outside.click();
    await expect(langMenu).toBeHidden();

    await page
      .getByRole("button", { name: /Select theme|Sélectionner le thème/ })
      .click();
    await expect(themeMenu).toBeVisible();
    await outside.click();
    await expect(themeMenu).toBeHidden();
  });

  test("desktop dropdown selects each theme", async ({ page }) => {
    await page.goto("/en");

    await expect(page.locator("html")).not.toHaveClass(/dark/);

    let { themeMenu } = await openDesktopThemeMenu(page);
    await themeMenu.getByRole("button", { name: "Dark", exact: true }).click();
    await expect(page.locator("html")).toHaveClass(/dark/);
    expect(await page.evaluate(() => localStorage.getItem("theme"))).toBe(
      "dark",
    );
    ({ themeMenu } = await openDesktopThemeMenu(page));
    await themeMenu.getByRole("button", { name: "Light", exact: true }).click();
    await expect(page.locator("html")).not.toHaveClass(/dark/);
    expect(await page.evaluate(() => localStorage.getItem("theme"))).toBe(
      "light",
    );
    ({ themeMenu } = await openDesktopThemeMenu(page));
    await themeMenu.getByRole("button", { name: "System", exact: true }).click();
    expect(await page.evaluate(() => localStorage.getItem("theme"))).toBe(
      "system",
    );
  });

  test("dark mode persists on reload", async ({ page }) => {
    await page.goto("/en");

    const { themeMenu } = await openDesktopThemeMenu(page);
    await themeMenu.getByRole("button", { name: "Dark", exact: true }).click();
    await expect(page.locator("html")).toHaveClass(/dark/);

    await page.reload();
    await expect(page.locator("html")).toHaveClass(/dark/);
  });

  test("dark mode survives AJAX nav", async ({ page }) => {
    await page.goto("/en");

    const { themeMenu } = await openDesktopThemeMenu(page);
    await themeMenu.getByRole("button", { name: "Dark", exact: true }).click();
    await expect(page.locator("html")).toHaveClass(/dark/);

    await page
      .locator('header#header .navbar-center a[href="/en/about"]')
      .click();
    await expect(page).toHaveURL(/\/en\/about/);

    await expect(page.locator("html")).toHaveClass(/dark/);
  });

  test("clicking theme switcher in mobile menu changes theme without closing the menu", async ({
    page,
  }) => {
    await page.goto("/en");
    await page.setViewportSize({ width: 375, height: 667 });

    await page.getByLabel("Open menu").click();
    const mobileMenu = page.locator(".drawer-side .menu");
    await expect(mobileMenu).toBeVisible();

    await page.getByRole("button", { name: "Dark", exact: true }).click();

    await expect(mobileMenu).toBeVisible();
    await expect(page.locator("html")).toHaveClass(/dark/);
  });
});

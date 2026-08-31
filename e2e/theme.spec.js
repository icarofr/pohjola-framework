import { test, expect } from "@playwright/test";

const themeDark = "pohjola-dark";
const themeLight = "pohjola";

test.describe("DaisyUI theme (data-theme)", () => {
  test("defaults without forced dark theme when localStorage is cleared", async ({
    page,
  }) => {
    await page.goto("/en");
    await page.evaluate(() => localStorage.removeItem("theme"));
    await page.reload();
    await expect(page.locator("html")).not.toHaveAttribute(
      "data-theme",
      themeDark,
    );
  });

  test("dark preference persists via data-theme on reload", async ({ page }) => {
    await page.goto("/en");
    await page.evaluate(
      ([dark]) => {
        localStorage.setItem("theme", "dark");
        document.documentElement.setAttribute("data-theme", dark);
      },
      [themeDark],
    );
    await page.reload();
    await expect(page.locator("html")).toHaveAttribute("data-theme", themeDark);
    expect(await page.evaluate(() => localStorage.getItem("theme"))).toBe(
      "dark",
    );
  });

  test("dark theme survives AJAX nav", async ({ page }) => {
    await page.goto("/en");
    await page.evaluate(
      ([dark]) => {
        localStorage.setItem("theme", "dark");
        document.documentElement.setAttribute("data-theme", dark);
      },
      [themeDark],
    );

    await page
      .locator('header nav.hidden.md\\:flex a[href="/en/about"]')
      .click();
    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page.locator("html")).toHaveAttribute("data-theme", themeDark);
  });

  test("theme dropdown sets dark mode and persists", async ({ page }) => {
    await page.goto("/en");
    await page.evaluate(() => localStorage.removeItem("theme"));

    await page.getByLabel("Select theme").click();
    await page.getByRole("button", { name: "Dark" }).click();

    await expect(page.locator("html")).toHaveAttribute("data-theme", themeDark);
    expect(await page.evaluate(() => localStorage.getItem("theme"))).toBe(
      "dark",
    );
  });

  test("light preference sets pohjola data-theme", async ({ page }) => {
    await page.goto("/en");
    await page.getByLabel("Select theme").click();
    await page.getByRole("button", { name: "Light" }).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", themeLight);
  });

  test("system preference removes data-theme", async ({ page }) => {
    await page.goto("/en");
    await page.evaluate(() => {
      localStorage.setItem("theme", "dark");
      document.documentElement.setAttribute("data-theme", "pohjola-dark");
    });
    await page.getByLabel("Select theme").click();
    await page.getByRole("button", { name: "System" }).click();
    await expect(page.locator("html")).not.toHaveAttribute("data-theme");
    expect(await page.evaluate(() => localStorage.getItem("theme"))).toBe(
      "system",
    );
  });
});

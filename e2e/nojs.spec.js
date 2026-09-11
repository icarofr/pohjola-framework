import { test, expect } from "@playwright/test";

// Tests that verify behaviour when JavaScript is disabled (no-js project)

test.describe("No-JS degradation", () => {
  test("home page renders hero headline", async ({ page }) => {
    await page.goto("/en");
    // hero headline is server rendered
    await expect(page.locator("main")).toContainText(
      "A framework built on guarantees, not conventions",
    );
  });

  test("navigation link performs full page load", async ({ page }) => {
    await page.goto("/en");
    const href = await page.getAttribute('a[href="/en/about"]', "href");
    // ensure link exists
    expect(href).toBe("/en/about");
    await page.goto(href);
    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page.locator("main")).toContainText("About");
  });

  test("about page renders correctly without JS", async ({ page }) => {
    await page.goto("/en/about");
    await expect(page.locator("main")).toContainText(
      "Songs from the North",
    );
  });

  test("language toggle links are present in markup", async ({ page }) => {
    await page.goto("/en");
    const frLink = await page.getAttribute('a[href="/fr"]', "href");
    expect(frLink).toBe("/fr");
    // navigate manually to French home
    await page.goto(frLink);
    await expect(page).toHaveURL(/\/fr$/);
    await expect(page.locator("html")).toHaveAttribute("lang", "fr");
    await expect(page.locator("main")).toContainText(
      "Un framework conçu pour sécuriser le code écrit par l'IA",
    );
  });
});

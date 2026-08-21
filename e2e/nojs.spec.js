import { test, expect } from "@playwright/test";

// Tests that verify behaviour when JavaScript is disabled (no-js project)

test.describe("No-JS degradation", () => {
  test("home page renders hero headline", async ({ page }) => {
    await page.goto("/en");
    // hero headline is server rendered
    await expect(page.locator("main")).toContainText(
      "The Type-Safe Functional Web Framework",
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

  test("community page renders correctly without JS", async ({ page }) => {
    await page.goto("/en/contact");
    await expect(page.locator("main")).toContainText(
      "Community & Contributing",
    );
    await expect(
      page.locator(
        'main a[href="https://github.com/icarofr/pohjola-framework/issues"]',
      ),
    ).toBeVisible();
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
      "Le framework web fonctionnel",
    );
  });
});

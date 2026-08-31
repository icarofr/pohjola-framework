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

    const menuButton = page.getByLabel("Open menu");
    await page.getByLabel("Close menu").waitFor({ state: "hidden" });

    await menuButton.click();
    await expect(page.getByLabel("Close menu")).toBeVisible();
    await expect(page.locator('div#content a[href="/en/about"]')).toBeVisible();

    await page.getByLabel("Close menu").click();
    await expect(page.getByLabel("Close menu")).toBeHidden();
  });

  test("mobile menu closes with Escape key", async ({ page }) => {
    await page.goto("/en");
    await page.setViewportSize({ width: 375, height: 667 });

    await page.getByLabel("Open menu").click();
    await expect(page.getByLabel("Close menu")).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(page.getByLabel("Close menu")).toBeHidden();
  });
});

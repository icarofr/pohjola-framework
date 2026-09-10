import { test, expect } from "@playwright/test";

test.describe("About", () => {
  test("about page renders heading and naming origin", async ({ page }) => {
    await page.goto("/en/about");

    await expect(page.locator("main")).toContainText("About Pohjola");
    await expect(page.locator("main")).toContainText("Songs from the North");
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

  test("mobile menu closes when a nav link is clicked", async ({ page }) => {
    await page.goto("/en");
    await page.setViewportSize({ width: 375, height: 667 });

    const drawerToggle = page.locator("#site-drawer");
    await page.getByLabel("Open menu").click();
    await expect(drawerToggle).toBeChecked();

    await page.locator('.drawer-side .menu a[href="/en/about"]').click();
    await expect(page).toHaveURL(/\/en\/about/);
    await expect(page.locator("div#content[data-page-title]")).toContainText(
      "About Pohjola",
    );
    await expect(drawerToggle).not.toBeChecked();
    await expect(page.getByLabel("Close menu")).toBeHidden();
  });
});

import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

/** Canonical routes and the template markers each must expose. */
const canonicalRoutes = [
  { path: "/en", marker: "landing-hero" },
  { path: "/en/about", marker: "page-header-breadcrumbs" },
  { path: "/en/contact", marker: "page-header-breadcrumbs" },
  { path: "/en/posts", marker: "feed-page" },
  { path: "/fr", marker: "landing-hero" },
  { path: "/fr/contact", marker: "hub-page" },
];

test.describe("Design regression", () => {
  for (const { path, marker } of canonicalRoutes) {
    test(`template marker ${path}`, async ({ page }) => {
      await page.goto(path);
      await expect(page.locator("main")).toBeVisible();
      await expect(page.locator(`[data-template="${marker}"]`)).toBeVisible();
    });

    test(`a11y ${path}`, async ({ page }) => {
      await page.goto(path);
      const results = await new AxeBuilder({ page })
        .include("main")
        .withTags(["wcag2a", "wcag2aa"])
        .analyze();
      expect(results.violations).toEqual([]);
    });
  }

  test("mobile drawer opens with distinct close control", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto("/en");

    const drawerToggle = page.locator("#site-drawer");
    await page.getByLabel("Open menu").click();
    await expect(drawerToggle).toBeChecked();
    await expect(page.locator(".drawer-side .menu")).toBeVisible();
    await expect(page.getByLabel("Close menu")).toBeVisible();
    await expect(page.getByLabel("Close sidebar")).toBeVisible();
  });
});

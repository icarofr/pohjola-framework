import { test, expect } from '@playwright/test'

test.describe('Theme switcher (Light / Dark / System cycle)', () => {
  test('clicking theme button cycles system -> light -> dark -> system', async ({ page }) => {
    await page.goto('/en')

    // Initial state: default system (no dark class in standard light mode test env)
    await expect(page.locator('html')).not.toHaveClass(/dark/)

    const themeToggle = page.locator('button[data-testid="theme-toggle"]').first()

    // 1st click: switches from system to light
    await themeToggle.click()
    await expect(page.locator('html')).not.toHaveClass(/dark/)
    let stored = await page.evaluate(() => localStorage.getItem('theme'))
    expect(stored).toBe('light')

    // 2nd click: switches from light to dark
    await themeToggle.click()
    await expect(page.locator('html')).toHaveClass(/dark/)
    stored = await page.evaluate(() => localStorage.getItem('theme'))
    expect(stored).toBe('dark')

    // 3rd click: switches from dark to system
    await themeToggle.click()
    stored = await page.evaluate(() => localStorage.getItem('theme'))
    expect(stored).toBe('system')
  })

  test('dark mode persists on reload', async ({ page }) => {
    await page.goto('/en')

    const themeToggle = page.locator('button[data-testid="theme-toggle"]').first()
    // Click twice (system -> light -> dark) to go to dark mode
    await themeToggle.click()
    await themeToggle.click()
    await expect(page.locator('html')).toHaveClass(/dark/)

    // Reload — dark mode should persist via localStorage
    await page.reload()
    await expect(page.locator('html')).toHaveClass(/dark/)
  })

  test('dark mode survives AJAX nav', async ({ page }) => {
    await page.goto('/en')

    const themeToggle = page.locator('button[data-testid="theme-toggle"]').first()
    // Click twice (system -> light -> dark) to go to dark mode
    await themeToggle.click()
    await themeToggle.click()
    await expect(page.locator('html')).toHaveClass(/dark/)

    // Navigate via AJAX
    await page.click('a[href="/en/about"]')
    await expect(page).toHaveURL(/\/en\/about/)

    // Dark mode should still be present
    await expect(page.locator('html')).toHaveClass(/dark/)
  })

  test('clicking theme switcher in mobile menu changes theme without closing the menu', async ({ page }) => {
    await page.goto('/en')
    await page.setViewportSize({ width: 375, height: 667 })

    // Open mobile menu
    await page.click('button[aria-label="Open menu"]')
    const mobileMenu = page.locator('#mobile-menu')
    await expect(mobileMenu).toBeVisible()

    // Click the theme switcher inside the mobile menu
    const mobileThemeToggle = mobileMenu.locator('button[data-testid="theme-toggle"]')
    await mobileThemeToggle.click()

    // Mobile menu must still be visible
    await expect(mobileMenu).toBeVisible()

    // Click again to cycle to dark
    await mobileThemeToggle.click()
    await expect(mobileMenu).toBeVisible()
    await expect(page.locator('html')).toHaveClass(/dark/)
  })
})


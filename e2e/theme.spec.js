import { test, expect } from '@playwright/test'

test.describe('Theme switcher (Light / Dark / System)', () => {
  test('selecting Dark theme adds dark class', async ({ page }) => {
    await page.goto('/en')

    // Initially no dark class
    await expect(page.locator('html')).not.toHaveClass(/dark/)

    // Open theme menu and select Dark
    await page.click('[aria-label="Toggle dark mode"]')
    await page.click('[data-theme="dark"]')

    // Dark class should be present
    await expect(page.locator('html')).toHaveClass(/dark/)
  })

  test('dark mode persists on reload', async ({ page }) => {
    await page.goto('/en')

    // Enable dark mode
    await page.click('[aria-label="Toggle dark mode"]')
    await page.click('[data-theme="dark"]')
    await expect(page.locator('html')).toHaveClass(/dark/)

    // Reload — dark mode should persist via localStorage
    await page.reload()
    await expect(page.locator('html')).toHaveClass(/dark/)
  })

  test('selecting Light theme removes dark class', async ({ page }) => {
    await page.goto('/en')

    // Enable dark mode first
    await page.click('[aria-label="Toggle dark mode"]')
    await page.click('[data-theme="dark"]')
    await expect(page.locator('html')).toHaveClass(/dark/)

    // Open theme menu and select Light
    await page.click('[aria-label="Toggle dark mode"]')
    await page.click('[data-theme="light"]')
    await expect(page.locator('html')).not.toHaveClass(/dark/)
  })

  test('selecting System theme sets system preference', async ({ page }) => {
    await page.goto('/en')

    // Open theme menu and select System
    await page.click('[aria-label="Toggle dark mode"]')
    await page.click('[data-theme="system"]')

    // localStorage should store 'system'
    const storedTheme = await page.evaluate(() => localStorage.getItem('theme'))
    expect(storedTheme).toBe('system')
  })

  test('dark mode survives AJAX nav', async ({ page }) => {
    await page.goto('/en')

    // Enable dark mode
    await page.click('[aria-label="Toggle dark mode"]')
    await page.click('[data-theme="dark"]')
    await expect(page.locator('html')).toHaveClass(/dark/)

    // Navigate via AJAX
    await page.click('a[href="/en/about"]')
    await expect(page).toHaveURL(/\/en\/about/)

    // Dark mode should still be present
    await expect(page.locator('html')).toHaveClass(/dark/)
  })
})


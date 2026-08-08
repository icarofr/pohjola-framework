import { test, expect } from '@playwright/test'

test.describe('Dark mode toggle', () => {
  test('clicking toggle adds dark class', async ({ page }) => {
    await page.goto('/en')

    // Initially no dark class
    await expect(page.locator('html')).not.toHaveClass(/dark/)

    // Click the dark mode toggle
    await page.click('[aria-label="Toggle dark mode"]')

    // Dark class should be present
    await expect(page.locator('html')).toHaveClass(/dark/)
  })

  test('dark mode persists on reload', async ({ page }) => {
    await page.goto('/en')

    // Enable dark mode
    await page.click('[aria-label="Toggle dark mode"]')
    await expect(page.locator('html')).toHaveClass(/dark/)

    // Reload — dark mode should persist via localStorage
    await page.reload()
    await expect(page.locator('html')).toHaveClass(/dark/)
  })

  test('dark mode can be toggled off', async ({ page }) => {
    await page.goto('/en')

    // Enable then disable
    await page.click('[aria-label="Toggle dark mode"]')
    await expect(page.locator('html')).toHaveClass(/dark/)

    await page.click('[aria-label="Toggle dark mode"]')
    await expect(page.locator('html')).not.toHaveClass(/dark/)
  })
  
  test('dark mode survives AJAX nav', async ({ page }) => {
    await page.goto('/en')
    
    // Enable dark mode
    await page.click('[aria-label="Toggle dark mode"]')
    await expect(page.locator('html')).toHaveClass(/dark/)
    
    // Navigate via AJAX
    await page.click('a[href="/en/about"]')
    await expect(page).toHaveURL(/\/en\/about/)
    
    // Dark mode should still be present
    await expect(page.locator('html')).toHaveClass(/dark/)
  })
})

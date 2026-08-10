import { test, expect } from '@playwright/test'

test.describe('Internationalization', () => {
  test('French language detection works', async ({ browser }) => {
    // locale sets the browser's Accept-Language properly (extraHTTPHeaders
    // is overridden by Chromium's own Accept-Language on navigation)
    const context = await browser.newContext({ locale: 'fr-FR' })
    const page = await context.newPage()
    await page.goto('/')

    // Should redirect to French version
    await expect(page).toHaveURL(/\/fr$/)

    // Should have French content in main
    await expect(page.locator('main')).toContainText('Votre titre ici')

    // HTML lang attribute should be French
    await expect(page.locator('html')).toHaveAttribute('lang', 'fr')
    await context.close()
  })
  
  test('language toggle flips HTML lang attribute', async ({ page }) => {
    await page.goto('/en')
    
    // Should start with English
    await expect(page.locator('html')).toHaveAttribute('lang', 'en')
    
    // Click language toggle to switch to French
    await page.click('button[aria-label="Switch language"]')
    await page.click('#lang-menu a[href="/fr"]')
    await expect(page).toHaveURL(/\/fr$/)
    
    // HTML lang should now be French
    await expect(page.locator('html')).toHaveAttribute('lang', 'fr')
  })
  
  test('mobile menu aria-expanded flips correctly', async ({ page }) => {
    await page.goto('/en')
    
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 })
    
    // Menu should start closed
    const menuButton = page.locator('button[aria-label="Open menu"]')
    await expect(menuButton).toHaveAttribute('aria-expanded', 'false')
    
    // Open menu
    await page.click('button[aria-label="Open menu"]')
    await expect(menuButton).toHaveAttribute('aria-expanded', 'true')
    
    // Close menu
    await page.click('button[aria-label="Open menu"]')
    await expect(menuButton).toHaveAttribute('aria-expanded', 'false')
  })
  
  test('banner text localizes correctly', async ({ page }) => {
    await page.goto('/en/contact?status=error')

    // Should show English error message
    await expect(page.locator('[data-form-status="error"]')).toContainText('Something went wrong')

    // French page shows the French banner
    await page.goto('/fr/contact?status=error')
    await expect(page.locator('[data-form-status="error"]')).toContainText('Une erreur est survenue')
  })
})

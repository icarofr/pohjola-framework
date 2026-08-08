import { test, expect } from '@playwright/test'

test.describe('Alpine AJAX navigation', () => {
  test('clicking a nav link swaps main content without reload', async ({ page }) => {
    await page.goto('/en')

    // Verify initial state
    await expect(page.locator('main')).toContainText('Your headline here')
    
    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      (window as any).__marker = 1
    })

    // Click the About link
    await page.click('a[href="/en/about"]')

    // URL should update
    await expect(page).toHaveURL(/\/en\/about/)

    // Page title should update
    await expect(page).toHaveTitle(/About/)

    // Main content should contain the About heading  
    await expect(page.locator('main')).toContainText('About')

    // Marker should still be 1 (no reload occurred)
    await expect(await page.evaluate(() => (window as any).__marker)).toBe(1)
  })

  test('clicking logo returns to home', async ({ page }) => {
    await page.goto('/en/about')
    
    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      (window as any).__marker = 1
    })
    
await page.click('a[href="/en"]')
      await expect(page).toHaveURL(/\/en$/)
      
      // Marker should still be 1 (no reload occurred)
      await expect(await page.evaluate(() => (window as any).__marker)).toBe(1)
  })

  test('language switch works via Alpine AJAX', async ({ page }) => {
    await page.goto('/en')
    
    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      (window as any).__marker = 1
    })

    await page.click('button[aria-label="Switch language"]')
    await page.click('#lang-menu a[href="/fr"]')
    await expect(page).toHaveURL(/\/fr$/)
    await expect(page.locator('main')).toContainText('Votre titre ici')
    
    // Marker should be gone (full reload occurred)
    await expect(await page.evaluate(() => (window as any).__marker)).toBeUndefined()
  })
  
  test('hero CTA button link navigation works without reload', async ({ page }) => {
    await page.goto('/en')
    
    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      (window as any).__marker = 1
    })
    
    // Click the hero CTA button link
    await page.click('a[href="/en/contact"]')
    
    // URL should update
    await expect(page).toHaveURL(/\/en\/contact/)
    
    // Title should update
    await expect(page).toHaveTitle(/Contact/)
    
    // Content should show contact page
    await expect(page.locator('main')).toContainText('Contact')
    
    // Marker should still be 1 (no reload occurred)
    await expect(await page.evaluate(() => (window as any).__marker)).toBe(1)
  })
  
  test('two AJAX navigations then goBack works correctly', async ({ page }) => {
    await page.goto('/en')
    
    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      (window as any).__marker = 1
    })
    
    // Navigate to About
    await page.click('a[href="/en/about"]')
    await expect(page).toHaveURL(/\/en\/about/)
    
    // Navigate to Contact
    await page.click('a[href="/en/contact"]')
    await expect(page).toHaveURL(/\/en\/contact/)
    
    // Go back — Alpine AJAX restores history but goBack triggers a full
    // reload (Alpine AJAX history limitation), so the marker is lost.
    await page.goBack()
    await expect(page).toHaveURL(/\/en\/about/)

    // Go back again
    await page.goBack()
    await expect(page).toHaveURL(/\/en$/)

    // Marker is gone — goBack caused a full reload (expected behaviour)
    await expect(await page.evaluate(() => (window as any).__marker)).toBeUndefined()
  })

  test('hover prefetch requests a fragment, not a full page', async ({ page }) => {
    await page.goto('/en')

    // Intercept the mouseenter fetch response via route interception
    let fragmentBody: string | undefined
    await page.route('**/en/about', async (route) => {
      const headers = route.request().headers()
      if (headers['x-alpine-request'] === 'true') {
        // Let it go to the server and capture the response
        const response = await route.fetch()
        fragmentBody = await response.text()
        await route.fulfill({ response })
      } else {
        await route.continue()
      }
    })

    // Hover over the About nav link — triggers @mouseenter prefetch
    await page.hover('nav a[href="/en/about"]')
    await page.waitForTimeout(500)

    // The mouseenter fetch should have been intercepted
    expect(fragmentBody).toBeTruthy()

    // The response should be a fragment (no <!DOCTYPE html>)
    expect(fragmentBody!).not.toContain('<!DOCTYPE')
    expect(fragmentBody!).toContain('<main')
  })
})

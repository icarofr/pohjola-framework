import { test, expect } from '@playwright/test'

test.describe('Alpine AJAX navigation', () => {
  test('clicking a nav link swaps main content without reload', async ({ page }) => {
    await page.goto('/en')

    // Verify initial state
    await expect(page.locator('main')).toContainText('The Type-Safe Functional Web Framework')
    
    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      window.__marker = 1
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
    expect(await page.evaluate(() => window.__marker)).toBe(1)
  })

  test('clicking logo returns to home', async ({ page }) => {
    await page.goto('/en/about')
    
    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      window.__marker = 1
    })
    
    await page.click('a[href="/en"]')
    await expect(page).toHaveURL(/\/en$/)
      
    // Marker should still be 1 (no reload occurred)
    expect(await page.evaluate(() => window.__marker)).toBe(1)
  })

  test('language switch works via Alpine AJAX', async ({ page }) => {
    await page.goto('/en')
    
    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      window.__marker = 1
    })

    await page.click('button[aria-label="Switch language"]')
    await page.click('#lang-menu a[href="/fr"]')
    await expect(page).toHaveURL(/\/fr$/)
    await expect(page.locator('main')).toContainText('Le framework web fonctionnel')
    
    // Marker should be gone (full reload occurred)
    expect(await page.evaluate(() => window.__marker)).toBeUndefined()
  })
  
  test('hero CTA button link navigation works without reload', async ({ page }) => {
    await page.goto('/en')
    
    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      window.__marker = 1
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
    expect(await page.evaluate(() => window.__marker)).toBe(1)
  })
  
  test('two AJAX navigations then goBack works correctly without reload', async ({ page }) => {
    await page.goto('/en')
    
    // Set marker to detect if full reload occurs
    await page.evaluate(() => {
      window.__marker = 1
    })
    
    // Navigate to About
    await page.click('a[href="/en/about"]')
    await expect(page).toHaveURL(/\/en\/about/)
    await expect(page).toHaveTitle(/About/)
    
    // Navigate to Contact
    await page.click('a[href="/en/contact"]')
    await expect(page).toHaveURL(/\/en\/contact/)
    await expect(page).toHaveTitle(/Contact/)
    
    // Go back to About — seamless SPA fragment swap (marker preserved!)
    await page.goBack()
    await expect(page).toHaveURL(/\/en\/about/)
    await expect(page).toHaveTitle(/About/)
    await expect(page.locator('main')).toContainText('About')
    expect(await page.evaluate(() => window.__marker)).toBe(1)

    // Go back to Home — seamless SPA fragment swap (marker preserved!)
    await page.goBack()
    await expect(page).toHaveURL(/\/en$/)
    await expect(page).toHaveTitle(/Pohjola/)
    await expect(page.locator('main')).toContainText('The Type-Safe Functional Web Framework')
    expect(await page.evaluate(() => window.__marker)).toBe(1)

    // Go forward to About
    await page.goForward()
    await expect(page).toHaveURL(/\/en\/about/)
    await expect(page).toHaveTitle(/About/)
    expect(await page.evaluate(() => window.__marker)).toBe(1)
  })

  test('hover prefetch requests a fragment, not a full page', async ({ page }) => {
    await page.goto('/en')

    // Intercept the mouseenter fetch response via route interception
    let fragmentBody
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
    expect(fragmentBody).not.toContain('<!DOCTYPE')
    expect(fragmentBody).toContain('<main')
  })
})

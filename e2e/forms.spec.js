import { test, expect } from '@playwright/test'

test.describe('Forms', () => {
  test('contact form has required fields', async ({ page }) => {
    await page.goto('/en/contact')

    // Check form exists
    const form = page.locator('form[action="/api/contact"]')
    await expect(form).toBeVisible()

    // Check required inputs
    await expect(page.locator('form[action="/api/contact"] input[name="name"][required]')).toBeVisible()
    await expect(page.locator('form[action="/api/contact"] input[name="email"][required]')).toBeVisible()
    await expect(page.locator('form[action="/api/contact"] textarea[name="message"][required]')).toBeVisible()
  })

  test('contact form submit button exists', async ({ page }) => {
    await page.goto('/en/contact')
    await expect(page.locator('form[action="/api/contact"] button[type="submit"]')).toBeVisible()
  })
  
  test('empty contact form submission shows error', async ({ page }) => {
    await page.goto('/en/contact')
    
    // Submit the form with empty fields
    // Fill required fields
    await page.locator('form[action="/api/contact"] input[name="name"]').fill('John Doe')
    await page.locator('form[action="/api/contact"] input[name="email"]').fill('john@example.com')
    await page.locator('form[action="/api/contact"] textarea[name="message"]').fill('Hello')
    // Submit
    await page.locator('form[action="/api/contact"]').getByRole('button', { name: 'Send' }).click()
    
    // Should redirect with error status (no RESEND_API_KEY)
    await expect(page).toHaveURL(/status=error/)
    // Error banner visible
    await expect(page.locator('[role="status"][data-form-status="error"]')).toBeVisible()
  })
  
  test('honeypot filled submits silently', async ({ page }) => {
    await page.goto('/en/contact')

    // Fill required fields (browser validation blocks submission otherwise)
    await page.locator('form[action="/api/contact"] input[name="name"]').fill('John Doe')
    await page.locator('form[action="/api/contact"] input[name="email"]').fill('john@example.com')
    await page.locator('form[action="/api/contact"] textarea[name="message"]').fill('Hello')

    // Fill the honeypot field (hidden — use evaluate since fill requires visibility)
    await page.locator('form[action="/api/contact"] input[name="website"]').evaluate((el) => { el.value = 'bot' })

    // Submit the form
    await page.locator('form[action="/api/contact"]').getByRole('button', { name: 'Send' }).click()

    // Should redirect to success page (silent success)
    await expect(page).toHaveURL(/status=success/)
  })
})

test.describe('Mobile menu', () => {
  test('mobile menu opens and closes', async ({ page }) => {
    await page.goto('/en')

    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 })

    // Menu should be hidden initially (x-cloak)
    const mobileNav = page.locator('#mobile-menu')
    await expect(mobileNav).toBeHidden()

    // Click hamburger
    await page.click('button[aria-label="Open menu"]')

    // Menu should be visible
    await expect(mobileNav).toBeVisible()
    
    // Click again to close
    await page.click('button[aria-label="Open menu"]')
    
    // Menu should be hidden again
    await expect(mobileNav).toBeHidden()
  })
  
  test('mobile menu closes with Escape key', async ({ page }) => {
    await page.goto('/en')

    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 })

    // Open menu
    await page.click('button[aria-label="Open menu"]')
    const mobileNav = page.locator('#mobile-menu')
    await expect(mobileNav).toBeVisible()
    
    // Close with Escape
    await page.keyboard.press('Escape')
    await expect(mobileNav).toBeHidden()
  })
})

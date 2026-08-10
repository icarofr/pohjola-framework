import { test, expect } from '@playwright/test'

test.describe('Static Assets', () => {
  test('css/styles.css returns 200 with correct content-type', async ({ page }) => {
    const response = await page.goto('/css/styles.css')
    expect(response?.status()).toBe(200)
    const contentType = response?.headers()['content-type']
    expect(contentType).toContain('text/css')
  })

  test('alpinejs.min.js returns 200', async ({ page }) => {
    const response = await page.goto('/assets/js/alpinejs.min.js')
    expect(response?.status()).toBe(200)
  })

  test('alpine-ajax.min.js returns 200', async ({ page }) => {
    const response = await page.goto('/assets/js/alpine-ajax.min.js')
    expect(response?.status()).toBe(200)
  })

  test('favicon.svg returns 200', async ({ page }) => {
    const response = await page.goto('/favicon.svg')
    expect(response?.status()).toBe(200)
  })

  test('server.js returns 404', async ({ page }) => {
    const response = await page.goto('/server.js')
    expect(response?.status()).toBe(404)
  })
})

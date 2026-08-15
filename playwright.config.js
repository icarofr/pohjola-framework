import { defineConfig, devices } from '@playwright/test'

const port = process.env.PORT || '3000'
const baseURL = process.env.BASE_URL || `http://localhost:${port}`

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL,
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'no-js',
      testMatch: '**/nojs.spec.js',
      use: {
        ...devices['Desktop Chrome'],
        javaScriptEnabled: false,
      },
    },
  ],
  webServer: {
    env: { PORT: port, BASE_URL: baseURL, RATE_LIMIT_MAX: '0' },
    command: 'make run',
    url: `${baseURL}/en`,
    reuseExistingServer: !process.env.CI && !process.env.PORT,
    timeout: 180_000
  }
})

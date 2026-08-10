import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3001',
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
    env: { PORT: '3001', BASE_URL: 'http://localhost:3001', RATE_LIMIT_MAX: '0' },
    command: 'make run',
    url: 'http://localhost:3001/en',
    reuseExistingServer: !process.env.CI,
    timeout: 180_000
  }
})

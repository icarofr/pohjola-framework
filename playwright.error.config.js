import { defineConfig } from "@playwright/test";

const port = process.env.ERROR_PORT || "3011";
const baseURL = process.env.BASE_URL || `http://127.0.0.1:${port}`;

export default defineConfig({
  testDir: "./e2e",
  testMatch: "**/error-fragment.spec.js",
  use: { baseURL },
  ...(process.env.BASE_URL
    ? {}
    : {
        webServer: {
          command: `PORT=${port} BASE_URL=http://127.0.0.1:${port} POSTS_API_BASE=http://127.0.0.1:9 RATE_LIMIT_MAX=0 make run`,
          url: `http://127.0.0.1:${port}/en`,
          timeout: 180_000,
          reuseExistingServer: false,
        },
      }),
});

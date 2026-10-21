import { existsSync } from 'node:fs';
import { defineConfig } from '@playwright/test';

const chromium = process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE || (existsSync('/usr/bin/chromium') ? '/usr/bin/chromium' : undefined);

export default defineConfig({
  testDir: 'tests-browser',
  fullyParallel: false,
  workers: 1,
  reporter: 'line',
  use: {
    baseURL: process.env.COMMUNE_TEST_URL || 'http://127.0.0.1:4173',
    ignoreHTTPSErrors: Boolean(process.env.COMMUNE_REAL_BACKEND),
    headless: true,
    launchOptions: chromium ? { executablePath: chromium } : {}
  }
});

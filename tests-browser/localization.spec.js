import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

const generated = fs.readFileSync(path.resolve('src/Generated/I18n.elm'), 'utf8');
const locales = ['en-US', 'zh-cmn-Hans-CN', 'zh-cmn-Hant-TW'];

function catalog(locale) {
  const escaped = locale.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = new RegExp(`messages\\.${escaped}\\.(\\d+)\\.json`).exec(generated);
  if (!match) throw new Error(`No generated catalog for ${locale}`);
  return {
    name: `messages.${locale}.${match[1]}.json`,
    body: fs.readFileSync(path.resolve('public/assets/i18n', `messages.${locale}.${match[1]}.json`), 'utf8')
  };
}

async function start(page, locale) {
  await page.addInitScript(value => localStorage.setItem('commune.locale', value), locale);
  await page.goto('/');
  await expect(page.locator('#main-heading')).toBeVisible();
}

function serve(route, locale, delay = 0) {
  return new Promise(resolve => setTimeout(resolve, delay)).then(() => {
    const file = catalog(locale);
    return route.fulfill({ status: 200, contentType: 'application/json; charset=utf-8', body: file.body });
  });
}

test('loads Simplified Chinese dynamically and restores language focus', async ({ page }) => {
  await start(page, 'zh-cmn-Hans-CN');
  await expect(page.locator('html')).toHaveAttribute('lang', 'zh-cmn-Hans-CN');
  await expect(page.getByRole('heading', { level: 1, name: '最新讨论' })).toBeVisible();
  await page.selectOption('#language-select', 'en-US');
  await expect(page.locator('html')).toHaveAttribute('lang', 'en-US');
  await expect(page.locator('#language-select')).toBeFocused();
});

test('falls back to English when the selected catalog is unavailable', async ({ page }) => {
  await page.route('**/messages.zh-cmn-Hant-TW.*.json', route => route.fulfill({ status: 404, body: 'missing' }));
  await start(page, 'zh-cmn-Hant-TW');
  await expect(page.locator('html')).toHaveAttribute('lang', 'en-US');
  await expect(page.getByText(/temporarily in English/)).toBeVisible();
  await expect(page.getByRole('status').filter({ hasText: 'temporarily in English' }).getByRole('button', { name: 'Try again' })).toBeVisible();
});

test('ignores a late response after a newer language choice', async ({ page }) => {
  await page.route('**/messages.zh-cmn-Hans-CN.*.json', route => serve(route, 'zh-cmn-Hans-CN', 650));
  await page.route('**/messages.zh-cmn-Hant-TW.*.json', route => serve(route, 'zh-cmn-Hant-TW', 40));
  await start(page, 'en-US');
  await page.selectOption('#language-select', 'zh-cmn-Hans-CN');
  await page.waitForTimeout(20);
  await page.selectOption('#language-select', 'zh-cmn-Hant-TW');
  await expect(page.locator('html')).toHaveAttribute('lang', 'zh-cmn-Hant-TW');
  await page.waitForTimeout(800);
  await expect(page.locator('html')).toHaveAttribute('lang', 'zh-cmn-Hant-TW');
  await expect(page.getByText('介面語言已切換為繁體中文。')).toBeVisible();
});

test('retains the active catalog when a replacement is malformed', async ({ page }) => {
  await page.route('**/messages.zh-cmn-Hant-TW.*.json', route => route.fulfill({ status: 200, contentType: 'text/html', body: '<h1>not json</h1>' }));
  await start(page, 'en-US');
  await page.selectOption('#language-select', 'zh-cmn-Hant-TW');
  await expect(page.locator('html')).toHaveAttribute('lang', 'en-US');
  await expect(page.getByText('Could not load 繁體中文. The current language remains active.')).toBeVisible();
  await expect(page.getByRole('heading', { level: 1, name: 'Latest discussions' })).toBeVisible();
});

test('rejects a response whose embedded catalog identity is wrong', async ({ page }) => {
  const english = catalog('en-US');
  await page.route('**/messages.zh-cmn-Hant-TW.*.json', route => route.fulfill({
    status: 200,
    contentType: 'application/json; charset=utf-8',
    body: english.body
  }));
  await start(page, 'en-US');
  await page.selectOption('#language-select', 'zh-cmn-Hant-TW');
  await expect(page.locator('html')).toHaveAttribute('lang', 'en-US');
  await expect(page.getByText('Could not load 繁體中文. The current language remains active.')).toBeVisible();
});

test('shows a semantic loading state before the first catalog arrives', async ({ page }) => {
  await page.route('**/messages.en-US.*.json', route => serve(route, 'en-US', 350));
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  await page.goto('/');
  await expect(page.getByRole('progressbar', { name: 'Commune' })).toBeVisible();
  await expect(page.getByRole('heading', { level: 1, name: 'Latest discussions' })).toBeVisible();
});

test('shows an exceptional recovery shell when all catalogs fail', async ({ page }) => {
  await page.route('**/assets/i18n/*.json', route => route.fulfill({ status: 503, body: 'unavailable' }));
  await startWithoutHeading(page, 'zh-cmn-Hant-TW');
  await expect(page.getByRole('heading', { name: 'Interface translations are unavailable' })).toBeVisible();
  await expect(page.locator('#boot-language-select')).toBeEnabled();
  await expect(page.getByRole('button', { name: 'Try again' })).toBeVisible();
});

async function startWithoutHeading(page, locale) {
  await page.addInitScript(value => localStorage.setItem('commune.locale', value), locale);
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Interface translations are unavailable' })).toBeVisible();
}

test('meets automated WCAG AA checks in every production locale', async ({ page }) => {
  for (const locale of locales) {
    await start(page, locale);
    const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
    expect(results.violations, `${locale}: ${JSON.stringify(results.violations, null, 2)}`).toEqual([]);
  }
});

test('keeps fallback and failure recovery states accessible', async ({ page }) => {
  await page.route('**/messages.zh-cmn-Hant-TW.*.json', route => route.fulfill({ status: 404, body: 'missing' }));
  await start(page, 'zh-cmn-Hant-TW');
  let results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
  expect(results.violations).toEqual([]);

  await page.unroute('**/messages.zh-cmn-Hant-TW.*.json');
  await page.route('**/assets/i18n/*.json', route => route.fulfill({ status: 503, body: 'unavailable' }));
  await page.reload();
  await expect(page.getByRole('heading', { name: 'Interface translations are unavailable' })).toBeVisible();
  results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
  expect(results.violations).toEqual([]);
});

test('supports RTL test layout and complex-script content', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  await page.goto('/?test-rtl');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
  await expect(page.locator('#language-select')).toBeVisible();
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
  expect(overflow).toBe(false);
});

test('remains usable with reduced motion and forced colors', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce', forcedColors: 'active' });
  await start(page, 'en-US');
  await expect(page.locator('#language-select')).toBeVisible();
  await expect(page.getByRole('navigation', { name: 'Main navigation' })).toBeVisible();
});

test('remains usable without page-level overflow at wide, medium, and compact widths', async ({ page }) => {
  for (const width of [1280, 768]) {
    await page.setViewportSize({ width, height: 800 });
    await start(page, 'en-US');
    await expect(page.getByRole('navigation', { name: 'Main navigation' })).toBeVisible();
    await expect(page.locator('#language-select')).toBeVisible();
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
    expect(overflow, `${width}px should not scroll horizontally`).toBe(false);
  }

  await page.setViewportSize({ width: 320, height: 800 });
  await start(page, 'en-US');
  await expect(page.getByRole('navigation', { name: 'Main navigation' })).toHaveCount(0);
  await page.getByRole('button', { name: 'Open navigation' }).click();
  const drawer = page.getByRole('dialog', { name: 'Main navigation' });
  await expect(drawer).toBeVisible();
  await expect(drawer.getByRole('navigation', { name: 'Main navigation' })).toBeVisible();
  await expect(page.locator('#language-select')).toBeVisible();
  const compactOverflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
  expect(compactOverflow, '320px should not scroll horizontally').toBe(false);
});

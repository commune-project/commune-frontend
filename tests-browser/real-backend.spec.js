import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

const enabled = Boolean(process.env.COMMUNE_REAL_BACKEND);
const base = process.env.COMMUNE_REAL_BACKEND_URL || 'https://localhost:8443';
const adminPassword = process.env.COMMUNE_REAL_ADMIN_PASSWORD || '';
const userPassword = process.env.COMMUNE_REAL_USER_PASSWORD || '';

test.describe('real backend', () => {
  test.skip(!enabled || !adminPassword || !userPassword, 'Configure COMMUNE_REAL_* credentials with the isolated HTTPS backend.');

  test('exercises authenticated forum workflows', async ({ page }) => {
    const suffix = Date.now().toString(36);
    const communityName = 'e2e-' + suffix;
    const communityTitle = 'E2E ' + suffix;
    const topicTitle = 'Real topic ' + suffix;

    await page.goto(base + '/login');
    await page.getByLabel('Username or email').fill('alice');
    await page.getByLabel('Password').fill(adminPassword);
    await page.getByRole('button', { name: 'Log in', exact: true }).click();
    await expect(page.locator('#navigation-drawer')).toContainText('@alice');
    await page.waitForTimeout(100);

    await page.goto(base + '/communities/new');
    await page.getByLabel('Community name').fill(communityName);
    await page.getByLabel('Community title').fill(communityTitle);
    await page.getByLabel('Federation mode').selectOption('local_only');
    await page.getByRole('button', { name: 'Create', exact: true }).click();
    await expect(page.getByText('Created successfully.')).toBeVisible();
    await page.waitForURL(url => /^\/communities\/[^/]+$/.test(url.pathname) && !url.pathname.endsWith('/new'));
    const communityId = page.url().split('/').pop();

    await page.getByRole('link', { name: 'Publish topic' }).click();
    await page.getByLabel('Topic title').fill(topicTitle);
    await page.getByLabel('Message').fill('Real backend body');
    await page.locator('#editor-file').setInputFiles({
      name: 'pixel.png', mimeType: 'image/png',
      buffer: Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAIAAAACAQAAAABazTCJAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAB3YoTpAAAAAd0SU1FB+oKFQYYMPYz+Q8AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMTAtMjFUMDY6MjQ6NDgrMDA6MDAnmYCZAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTEwLTIxVDA2OjI0OjQ4KzAwOjAwVsQ4JQAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0xMC0yMVQwNjoyNDo0OCswMDowMAHRGfoAAAAMSURBVAjXYzjAcAAAAwQBgcU7oqkAAAAASUVORK5CYII=', 'base64')
    });
    await expect(page.getByLabel('Message')).toHaveValue(/api\/v1\/media/);
    await page.getByRole('button', { name: 'Publish topic' }).click();
    await expect(page).toHaveURL(new RegExp('/posts/[^/]+$'));
    const postId = page.url().split('/').pop();
    await expect(page.getByRole('heading', { level: 1, name: topicTitle })).toBeVisible();

    const like = page.getByRole('article', { name: topicTitle }).getByRole('button', { name: /^Like/ });
    await like.click();
    await expect(page.getByRole('article', { name: topicTitle }).getByRole('button', { name: /^Unlike/ })).toBeVisible();

    await page.getByRole('link', { name: 'Edit post' }).click();
    await page.getByLabel('Topic title').fill(topicTitle + ' edited');
    await page.getByRole('button', { name: 'Save changes' }).click();
    await expect(page.getByRole('heading', { level: 1, name: topicTitle + ' edited' })).toBeVisible();

    await page.goto(base + '/communities/' + communityId + '/manage');
    await expect(page.getByRole('heading', { name: 'Manage community' })).toBeVisible();
    await page.getByLabel('Actor URI').fill('https://localhost:8443/users/bob');
    await page.getByRole('button', { name: 'Add member' }).click();
    await page.getByLabel('Post ID').fill(postId);
    await page.getByRole('button', { name: 'Accept submission' }).click();

    await page.getByRole('button', { name: 'Log out' }).click();
    await expect(page).toHaveURL(/\/login$/);
    await page.getByLabel('Username or email').fill('bob');
    await page.getByLabel('Password').fill(userPassword);
    await page.getByRole('button', { name: 'Log in', exact: true }).click();
    await expect(page.getByText(/Signed in as bob/)).toBeVisible();
    await page.waitForTimeout(100);
    await page.goto(base + '/posts/' + postId);
    await page.getByRole('button', { name: 'Reply', exact: true }).click();
    await page.getByLabel('Message').fill('Bob replies from the real backend');
    await page.getByRole('button', { name: 'Publish reply' }).click();
    await expect(page.getByText('Bob replies from the real backend')).toBeVisible();
    const replyHref = await page.getByRole('article').filter({ hasText: 'Bob replies from the real backend' }).getByRole('link').first().getAttribute('href');

    await page.getByRole('button', { name: 'Log out' }).click();
    await page.getByLabel('Username or email').fill('alice');
    await page.getByLabel('Password').fill(adminPassword);
    await page.getByRole('button', { name: 'Log in', exact: true }).click();
    await page.waitForTimeout(100);

    await page.goto(base + '/search?kind=posts&q=' + encodeURIComponent(topicTitle));
    await expect(page.getByRole('link', { name: topicTitle + ' edited' })).toBeVisible();

    await page.goto(base + '/settings/profile');
    await page.getByLabel('Display name').fill('Alice E2E');
    await page.getByRole('button', { name: 'Save profile' }).click();
    await expect(page.getByText('Changes saved.')).toBeVisible();

    let notified = false;
    for (let attempt = 0; attempt < 12 && !notified; attempt += 1) {
      await page.goto(base + '/notifications');
      notified = await page.locator('.notification-list a[href="' + replyHref + '"]').first().isVisible().catch(() => false);
      if (!notified) await page.waitForTimeout(1000);
    }
    expect(notified, 'notification worker should project Bob\'s reply').toBe(true);

    await page.goto(base + '/register');
    await page.getByLabel('Username').fill('disabled-user');
    await page.getByLabel('Email').fill('disabled-user@example.org');
    await page.getByRole('button', { name: 'Create account' }).click();
    await expect(page.getByText('This action is not allowed, or your access has changed.')).toBeVisible();

    const axe = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
    expect(axe.violations).toEqual([]);
  });
});

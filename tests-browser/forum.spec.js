import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

const identity = {
  site_id: 'a', account_id: 1, actor_uri: 'https://forum.test/users/alice', username: 'alice',
  roles: { site_administrator: true, deployment_superadministrator: false }
};

function fixtures() {
  const community = {
    id: 'c1', name: 'news', title: 'News', description: 'Daily news',
    federation_mode: 'federated', read_policy: 'eligible_users', post_policy: 'members',
    host_site_id: 'a',
    viewer: { is_member: true, is_creator: true, is_manager: true, management_scope: 'community' },
    permissions: { can_post: true, can_manage: true, can_manage_members: true, can_manage_managers: true }
  };
  const topic = {
    id: 'p1', community_id: 'c1', object_type: 'Page', title: 'Hello world', body: 'Hello',
    body_html: '<p>Hello <strong>world</strong></p><p dir="auto">مرحبا — नमस्ते — สวัสดี — 你好 — é — 👩‍💻</p>', author_actor_uri: identity.actor_uri,
    author: { acct: 'alice@forum.test', display_name: 'Alice' },
    authored_at: '2026-10-20T08:30:00Z', version: 4, content_format: 'markdown',
    like_count: 2, liked_by_me: false, reply_count: 1, deleted: false,
    permissions: { can_edit: true, can_delete: true, can_like: true, can_reply: true, can_hide: true, can_moderate: true },
    attachments: [{ url: '/api/v1/media/file1', media_type: 'application/pdf', name: 'notes.pdf' }]
  };
  const reply = {
    ...topic, id: 'r1', object_type: 'Note', title: '', body: 'A reply', body_html: '<p>A reply</p>',
    parent_id: 'p1', reply_count: 1,
    permissions: { ...topic.permissions, can_edit: false, can_delete: false }
  };
  const nestedReply = { ...reply, id: 'r1r1', body: 'Nested answer', body_html: '<p>Nested answer</p>', parent_id: 'r1', reply_count: 0 };
  return {
    signedIn: false,
    posts: { p1: topic },
    replies: { p1: [reply], r1: [nestedReply] },
    communities: [community],
    calls: [],
    likes: new Map(),
    conflictOnce: false,
    loginStatus: 200,
    mediaStatus: 201
  };
}

function json(route, status, body) {
  return route.fulfill({ status, contentType: 'application/json; charset=utf-8', body: JSON.stringify(body) });
}

function pageOf(items, limit = 20, offset = 0) {
  return { items, limit, offset };
}

async function mockApi(page, state, { authenticated = false } = {}) {
  state.signedIn = authenticated;
  await page.route('**/api/v1/**', async route => {
    const request = route.request();
    const url = new URL(request.url());
    const path = url.pathname;
    const method = request.method();
    let body = {};
    try { body = request.postDataJSON() || {}; } catch { body = {}; }
    state.calls.push({ method, path, search: url.search, body });

    if (path === '/api/v1/auth/session') {
      return state.signedIn ? json(route, 200, identity) : json(route, 401, { error: 'unauthenticated' });
    }
    if (path === '/api/v1/auth/login' && method === 'POST') {
      if (state.loginStatus !== 200) return json(route, state.loginStatus, { error: 'invalid credentials' });
      state.signedIn = true;
      return json(route, 200, identity);
    }
    if (path === '/api/v1/auth/logout') {
      state.signedIn = false;
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/auth/register' && method === 'POST') {
      return route.fulfill({ status: 202 });
    }
    if (path === '/api/v1/auth/verification/resend' && method === 'POST') {
      return route.fulfill({ status: 202 });
    }
    if (path === '/api/v1/auth/verification/confirm' && method === 'POST') {
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/media' && method === 'POST') {
      if (state.mediaStatus !== 201) return json(route, state.mediaStatus, { error: 'invalid image' });
      return json(route, 201, { id: 'upload1', purpose: 'post', media_type: 'image/png', size: 4, name: 'pixel.png', reference: '/api/v1/media/upload1', preview_url: '/api/v1/media/upload1/preview' });
    }
    if (path === '/api/v1/notifications/unread-count') {
      return json(route, 200, { count: 2 });
    }
    if (path === '/api/v1/notifications' && method === 'GET') {
      return json(route, 200, { items: [{ id: 1, kind: 'reply', post_id: 'p1', actor_uri: 'https://forum.test/users/bob', created_at: '2026-10-20T08:30:00Z', read: false }], limit: 20, offset: 0, through_cursor: '2026-10-20T08:30:00Z|1' });
    }
    if (path === '/api/v1/notifications/1/read' || path === '/api/v1/notifications/read-all') {
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/topics') {
      return json(route, 200, pageOf(Object.values(state.posts)));
    }
    if (path === '/api/v1/communities' && method === 'GET') {
      return json(route, 200, pageOf(state.communities));
    }
    if (path === '/api/v1/communities' && method === 'POST') {
      const community = { ...state.communities[0], id: 'c2', name: body.name, title: body.title, federation_mode: body.mode, read_policy: body.read_policy, post_policy: body.post_policy };
      state.communities.push(community);
      return json(route, 201, community);
    }
    if (path === '/api/v1/search') {
      return json(route, 200, pageOf(url.searchParams.get('kind') === 'communities' ? state.communities : Object.values(state.posts)));
    }
    if (path === '/api/v1/profile') {
      if (method === 'PATCH') {
        const profile = { actor_uri: identity.actor_uri, username: 'alice', display_name: body.display_name, biography: body.biography, biography_html: '<p>' + body.biography + '</p>', avatar_url: '', updated_at: '2026-10-20T08:30:00Z' };
        state.profile = profile;
        return json(route, 200, profile);
      }
      return json(route, 200, state.profile || { actor_uri: identity.actor_uri, username: 'alice', display_name: 'Alice', biography: 'Bio', biography_html: '<p>Bio</p>', avatar_url: '', updated_at: '2026-10-20T08:30:00Z' });
    }
    if (path === '/api/v1/profiles/alice') {
      return json(route, 200, state.profile || { actor_uri: identity.actor_uri, username: 'alice', display_name: 'Alice', biography: 'Bio', biography_html: '<p>Bio</p>', avatar_url: '', updated_at: '2026-10-20T08:30:00Z' });
    }
    if (path === '/api/v1/communities/c1' && method === 'GET') {
      return json(route, 200, state.communities[0]);
    }
    if (path === '/api/v1/communities/c2' && method === 'GET') {
      return json(route, 200, state.communities.find(community => community.id === 'c2'));
    }
    if (path === '/api/v1/communities/c1/topics' && method === 'GET') {
      return json(route, 200, pageOf(Object.values(state.posts)));
    }
    if (path === '/api/v1/communities/c2/topics' && method === 'GET') {
      return json(route, 200, pageOf([]));
    }
    if (path === '/api/v1/communities/c1/topics' && method === 'POST') {
      const created = { ...state.posts.p1, id: 'p-new', title: body.title, body: body.body, body_html: '<p>' + body.body + '</p>', version: 1, reply_count: 0, like_count: 0 };
      state.posts['p-new'] = created;
      state.replies['p-new'] = [];
      return json(route, 201, created);
    }
    if (path === '/api/v1/communities/c1/members' && method === 'GET') {
      return json(route, 200, pageOf([{ actor_uri: identity.actor_uri, is_creator: true, is_manager: false }]));
    }
    if (path === '/api/v1/communities/c1/managers' && method === 'GET') {
      return json(route, 200, pageOf([{ actor_uri: identity.actor_uri, is_creator: true, is_manager: true }]));
    }
    if (path === '/api/v1/communities/c1/policy') {
      return route.fulfill({ status: 204 });
    }
    if (path.startsWith('/api/v1/communities/c1/members') || path.startsWith('/api/v1/communities/c1/managers')) {
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/communities/c1/removals' || path === '/api/v1/communities/c1/submissions') {
      return route.fulfill({ status: 204 });
    }
    if (path.startsWith('/api/v1/posts/') && path.endsWith('/likes')) {
      return route.fulfill({ status: 204 });
    }
    if (path.startsWith('/api/v1/posts/') && path.endsWith('/hide')) {
      return route.fulfill({ status: 204 });
    }
    if (path.startsWith('/api/v1/posts/') && path.endsWith('/source')) {
      const id = path.split('/')[4];
      const post = state.posts[id];
      return json(route, 200, { id, title: post.title, body: post.body, updated_at: '2026-10-20T08:30:00Z', version: post.version, content_format: post.content_format, attachment_ids: [] });
    }
    if (path === '/api/v1/posts/p1/replies' && method === 'GET') {
      return json(route, 200, pageOf(state.replies.p1));
    }
    if (path === '/api/v1/posts/p1/replies' && method === 'POST') {
      const created = { ...state.posts.p1, id: 'r2', object_type: 'Note', title: '', body: body.body, body_html: '<p>' + body.body + '</p>', parent_id: 'p1', version: 1, reply_count: 0 };
      state.replies.p1.push(created);
      state.replies.r2 = [];
      return json(route, 201, created);
    }
    if (path === '/api/v1/posts/r1/replies' || path === '/api/v1/posts/p-new/replies' || path === '/api/v1/posts/r2/replies') {
      const id = path.split('/')[4];
      return json(route, 200, pageOf(state.replies[id] || []));
    }
    if (path.startsWith('/api/v1/posts/')) {
      const id = path.split('/')[4];
      if (method === 'PATCH') {
        const post = state.posts[id];
        if (state.conflictOnce) {
          state.conflictOnce = false;
          state.posts[id] = { ...post, title: 'Server version', version: post.version + 1 };
          return json(route, 409, { error: 'edit_conflict' });
        }
        state.posts[id] = { ...post, title: body.title, body: body.body, version: post.version + 1 };
        return json(route, 200, state.posts[id]);
      }
      if (method === 'DELETE') {
        return route.fulfill({ status: 204 });
      }
      return state.posts[id] ? json(route, 200, state.posts[id]) : json(route, 404, { error: 'not found' });
    }
    if (path === '/api/v1/contexts/ctx1/backfill') {
      return json(route, 200, { examined: 1, imported: 1, updated: 0, pages: 1 });
    }
    if (path.startsWith('/api/v1/posts/') && path.endsWith('/import')) {
      return json(route, 201, state.posts.p1);
    }
    return json(route, 404, { error: 'not found' });
  });
}

async function open(page, path, authenticated = true) {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  await page.goto(path);
  await expect(page.locator('#main-heading')).toBeVisible();
}

test('browse latest, community, discussion, search and profile', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/');
  await expect(page.getByRole('heading', { name: 'Latest discussions' }).first()).toBeVisible();
  await expect(page.getByRole('link', { name: 'Hello world' })).toBeVisible();
  await expect(page.getByText('Alice (@alice@forum.test)').first()).toBeVisible();
  await expect(page.getByText(/مرحبا/)).toBeVisible();

  await page.getByRole('link', { name: 'Communities' }).click();
  await expect(page.getByRole('heading', { name: 'News' })).toBeVisible();
  await page.getByRole('link', { name: 'News' }).click();
  await expect(page.getByRole('link', { name: 'Publish topic' })).toBeVisible();

  await page.getByRole('link', { name: 'Hello world' }).click();
  await expect(page.getByRole('heading', { level: 1, name: 'Hello world' })).toBeVisible();
  await expect(page.getByRole('heading', { level: 1, name: 'Hello world' })).toBeFocused();
  await expect(page).toHaveTitle('Hello world · Commune');
  await expect(page.getByText('A reply')).toBeVisible();
  await expect(page.locator('time[data-commune-time]').first()).not.toHaveText(/^2026-\d/);
  const replyArticle = page.getByRole('article').filter({ hasText: 'A reply' });
  await replyArticle.getByRole('button', { name: '1 reply' }).click();
  await expect(page.getByText('Nested answer')).toBeVisible();
  await page.goBack();
  await expect(page.getByRole('heading', { level: 1, name: 'News' })).toBeVisible();
  await page.goBack();
  await expect(page.getByRole('heading', { level: 1, name: 'Communities' })).toBeVisible();
  await page.goBack();
  await expect(page.getByRole('heading', { level: 1, name: 'Latest discussions' })).toBeVisible();

  await page.goto('/search?kind=posts&q=Hello');
  await expect(page.getByRole('heading', { name: 'Search' })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Hello world' })).toBeVisible();

  await page.goto('/profiles/alice');
  await expect(page.getByRole('heading', { name: 'Alice' })).toBeVisible();
});

test('logs in, registers, verifies and logs out', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: false });
  await open(page, '/login');
  await page.getByLabel('Username or email').fill('alice');
  await page.getByLabel('Password').fill('long-enough-password');
  await page.getByRole('button', { name: 'Log in' }).click();
  await expect(page).toHaveURL(/\/$|\/$/);
  await expect(page.getByText(/Signed in as alice/)).toBeVisible();

  await page.goto('/register');
  await page.getByLabel('Username').fill('alice');
  await page.getByLabel('Email').fill('alice@example.org');
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByText(/Check your email/)).toBeVisible();

  await page.goto('/verify-email#token=secret-token');
  expect(new URL(page.url()).hash).toBe('');
  expect(await page.evaluate(token => Object.values(localStorage).some(value => value.includes(token)), 'secret-token')).toBe(false);
  await page.getByLabel('Password').fill('another-long-password');
  await page.getByRole('button', { name: 'Finish registration' }).click();
  await expect(page.getByRole('status').filter({ hasText: 'Email verified. You can now log in.' }).first()).toBeVisible();
});

test('ignores an old route failure after navigating away', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/');
  await expect(page.getByText(/Signed in as alice/)).toBeVisible();
  let pending;
  await page.route('**/api/v1/posts/p1', route => { pending = route; });
  await page.getByRole('link', { name: 'Hello world' }).click();
  await expect.poll(() => Boolean(pending)).toBe(true);
  await page.getByRole('link', { name: 'Communities', exact: true }).click();
  await expect(page.getByRole('heading', { level: 1, name: 'Communities' })).toBeVisible();
  const response = page.waitForResponse('**/api/v1/posts/p1');
  await json(pending, 401, { error: 'expired old request' });
  await (await response).finished();
  await page.waitForTimeout(100);
  await expect(page.getByText(/Signed in as alice/)).toBeVisible();
  await expect(page.getByText('Your session has expired. Please log in again.')).toHaveCount(0);
});

test('ignores startup session data after login and logout', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state);
  let pending;
  await page.route('**/api/v1/auth/session', route => { pending = route; });
  await open(page, '/login');
  await expect.poll(() => Boolean(pending)).toBe(true);
  await page.getByLabel('Username or email').fill('alice');
  await page.getByLabel('Password').fill('long-enough-password');
  await page.getByRole('button', { name: 'Log in' }).click();
  await expect(page.getByText(/Signed in as alice/)).toBeVisible();
  await page.getByRole('button', { name: 'Log out' }).click();
  await expect(page.getByLabel('Username or email')).toBeVisible();
  const response = page.waitForResponse('**/api/v1/auth/session');
  await json(pending, 200, identity);
  await (await response).finished();
  await page.waitForTimeout(100);
  await expect(page.getByLabel('Username or email')).toBeVisible();
  await expect(page.getByText(/Signed in as alice/)).toHaveCount(0);
});

test('clears private profile drafts on session expiry', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/settings/profile');
  await page.getByLabel('Display name').fill('Private unsaved name');
  await page.route('**/api/v1/profile', route => json(route, 401, { error: 'session expired' }));
  await page.getByRole('button', { name: 'Save profile' }).click();
  await expect(page.getByText('Your session has expired. Please log in again.').first()).toBeVisible();
  // Existing mutation errors retain the draft; a protected read expires the session.
  await expect(page.getByLabel('Display name')).toHaveValue('Private unsaved name');
  await page.route('**/api/v1/topics?*', route => json(route, 401, { error: 'session expired' }));
  await page.getByRole('link', { name: 'Latest discussions', exact: true }).click();
  await expect(page.getByText(/Signed in as alice/)).toHaveCount(0);
  await expect(page.getByLabel('Display name')).toHaveCount(0);
  await page.unroute('**/api/v1/topics?*');
  await page.unroute('**/api/v1/profile');
  // Keep the next profile read from replacing the cleared form with server values.
  await page.route('**/api/v1/profile', route => json(route, 503, { error: 'temporarily unavailable' }));
  await page.getByRole('link', { name: 'Log in', exact: true }).first().click();
  await page.getByLabel('Username or email').fill('alice');
  await page.getByLabel('Password').fill('long-enough-password');
  await page.getByRole('button', { name: 'Log in' }).click();
  await expect(page.getByText(/Signed in as alice/)).toBeVisible();
  await page.getByRole('link', { name: 'Profile settings', exact: true }).click();
  await expect(page.getByLabel('Display name')).toHaveValue('');
});

test('invalid login keeps the identifier and associates a localized error', async ({ page }) => {
  const state = fixtures();
  state.loginStatus = 401;
  await mockApi(page, state, { authenticated: false });
  await open(page, '/login');
  await page.getByLabel('Username or email').fill('alice');
  await page.getByLabel('Password').fill('wrong-password');
  await page.getByLabel('Username or email').dispatchEvent('compositionstart');
  await page.getByLabel('Username or email').press('Enter');
  await expect(page).toHaveURL(/\/login$/);
  await page.getByLabel('Username or email').dispatchEvent('compositionend');
  await page.getByRole('button', { name: 'Log in' }).click();
  await expect(page.getByRole('alert')).toContainText('The username, email, or password was not accepted.');
  await expect(page.getByLabel('Username or email')).toHaveValue('alice');
});

test('creates and edits content with attachment upload', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1/new');
  await page.getByLabel('Topic title').fill('New topic');
  await page.getByLabel('Message').fill('Body text');
  await page.getByLabel('Topic title').dispatchEvent('compositionstart');
  await page.getByLabel('Topic title').press('Enter');
  await expect(page).toHaveURL(/\/communities\/c1\/new$/);
  await page.getByLabel('Topic title').dispatchEvent('compositionend');
  await page.selectOption('#language-select', 'zh-cmn-Hans-CN');
  await expect(page.getByLabel('主题标题')).toHaveValue('New topic');
  await expect(page.getByLabel('正文')).toHaveValue('Body text');
  await page.selectOption('#language-select', 'en-US');
  await expect(page.getByLabel('Topic title')).toHaveValue('New topic');
  await page.locator('#editor-file').setInputFiles({ name: 'pixel.png', mimeType: 'image/png', buffer: Buffer.from([1,2,3,4]) });
  await expect(page.getByLabel('Message')).toHaveValue(/upload1/);
  await page.getByRole('button', { name: 'Publish topic' }).click();
  await expect(page).toHaveURL(/\/posts\/p-new$/);

  await page.goto('/posts/p1');
  await page.getByRole('button', { name: 'Reply', exact: true }).click();
  await page.getByLabel('Message').fill('A new reply');
  await page.getByRole('button', { name: 'Publish reply' }).click();
  await expect(page).toHaveURL(/\/posts\/p1$/);
  await expect(page.getByText('A new reply')).toBeVisible();

  await page.goto('/posts/p1/edit');
  await expect(page.getByLabel('Topic title')).toHaveValue('Hello world');
  await page.getByLabel('Topic title').fill('Edited');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page).toHaveURL(/\/posts\/p1$/);
  const editCall = state.calls.find(call => call.method === 'PATCH' && call.path === '/api/v1/posts/p1');
  expect(editCall.body.expected_version).toBe(4);
  expect(typeof editCall.body.expected_version).toBe('number');
});

test('creates a community with a valid policy pair', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/new');
  await page.getByLabel('Community name').fill('local-news');
  await page.getByLabel('Community title').fill('Local News');
  await page.getByLabel('Federation mode').selectOption('local_only');
  await page.getByLabel('Who can post').selectOption('members');
  await page.getByRole('button', { name: 'Create', exact: true }).click();
  await expect(page).toHaveURL(/\/communities\/c2$/);
  await expect(page.getByText('Local News')).toBeVisible();
});

test('searches Chinese text with URL-backed filters', async ({ page }) => {
  const state = fixtures();
  const chinese = { ...state.posts.p1, id: 'p-cn', title: '中文标题', body: '中文内容', body_html: '<p>中文内容</p>' };
  state.posts['p-cn'] = chinese;
  await mockApi(page, state, { authenticated: true });
  await open(page, '/search?kind=posts&q=' + encodeURIComponent('中文'));
  await expect(page.getByRole('link', { name: '中文标题' })).toBeVisible();
  const search = state.calls.find(call => call.path === '/api/v1/search');
  expect(search.search).toContain('q=%E4%B8%AD%E6%96%87');
});

test('preserves an edit draft when the server reports a conflict', async ({ page }) => {
  const state = fixtures();
  state.conflictOnce = true;
  await mockApi(page, state, { authenticated: true });
  await open(page, '/posts/p1/edit');
  await page.getByLabel('Topic title').fill('My concurrent draft');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.getByText(/Another edit changed this post/)).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Latest source' })).toBeVisible();
  await expect(page.getByLabel('Topic title')).toHaveValue('My concurrent draft');
  await page.getByRole('button', { name: 'Replace draft with latest source' }).click();
  await expect(page.getByLabel('Topic title')).toHaveValue('Server version');
});

test('likes, deletes with accessible confirmation, and updates profile', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/posts/p1');
  const topicCard = page.getByRole('article', { name: 'Hello world' });
  await expect(topicCard.getByRole('button', { name: /^Like/ })).toHaveAttribute('aria-pressed', 'false');
  await topicCard.getByRole('button', { name: /^Like/ }).click();
  const unlike = topicCard.getByRole('button', { name: /^Unlike/ });
  await expect(unlike).toBeVisible();
  await expect(unlike).toHaveAttribute('aria-pressed', 'true');

  await page.getByRole('button', { name: 'Delete post' }).click();
  await expect(page.getByRole('dialog', { name: 'Delete this post?' })).toBeVisible();
  await page.getByRole('button', { name: 'Cancel' }).click();
  await expect(page.getByRole('button', { name: 'Delete post' })).toBeFocused();
  await page.getByRole('button', { name: 'Delete post' }).click();
  await page.getByRole('dialog', { name: 'Delete this post?' }).getByRole('button', { name: 'Delete post' }).click();
  await expect(page).toHaveURL(/\/$/);

  await page.goto('/settings/profile');
  await page.getByLabel('Display name').fill('Alice Updated');
  await page.getByLabel('Avatar').setInputFiles({ name: 'avatar.png', mimeType: 'image/png', buffer: Buffer.from([1, 2, 3, 4]) });
  await expect(page.locator('img.avatar')).toHaveAttribute('src', '/api/v1/media/upload1/preview');
  await page.getByRole('button', { name: 'Save profile' }).click();
  await expect(page.getByText('Changes saved.')).toBeVisible();
});

test('post action icons keep one row, localized tooltips and focus order', async ({ page }) => {
  const state = fixtures();
  state.posts.p1.reply_count = 3;
  await mockApi(page, state, { authenticated: true });
  await page.setViewportSize({ width: 320, height: 800 });
  await open(page, '/posts/p1');

  const card = page.getByRole('article', { name: 'Hello world' });
  const actions = card.locator('.post-actions .icon-button');
  await expect(actions).toHaveCount(4);

  const tops = await actions.evaluateAll(nodes => nodes.map(node => Math.round(node.getBoundingClientRect().top)));
  expect(new Set(tops).size).toBe(1);

  const glyphTops = await actions.locator('svg').evaluateAll(nodes => nodes.map(node => Math.round(node.getBoundingClientRect().top)));
  expect(new Set(glyphTops).size).toBe(1);

  const [iconBox, countBox] = await actions.nth(0).evaluate(node => {
    const icon = node.querySelector('svg').getBoundingClientRect();
    const count = node.querySelector('.action-count').getBoundingClientRect();
    return [{ right: icon.right, top: icon.top }, { left: count.left, top: count.top }];
  });
  expect(countBox.left).toBeGreaterThanOrEqual(iconBox.right);
  expect(Math.abs(countBox.top - iconBox.top)).toBeLessThanOrEqual(4);

  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(0);

  await expect(actions.nth(0)).toHaveAttribute('title', 'Like · 2 likes');
  await expect(actions.nth(1)).toHaveAttribute('title', 'Edit post');
  await expect(actions.nth(2)).toHaveAttribute('title', 'Delete post');
  await expect(actions.nth(3)).toHaveAttribute('title', '3 replies');
  await expect(actions.nth(0).locator('.action-count')).toHaveText('2');
  await expect(actions.nth(3).locator('.action-count')).toHaveText('3');
  await expect(card.getByRole('button', { name: 'Like · 2 likes' })).toBeVisible();
  await expect(card.getByRole('button', { name: '3 replies' })).toBeVisible();

  await actions.nth(0).focus();
  await page.keyboard.press('Tab');
  await expect(actions.nth(1)).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(actions.nth(2)).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(actions.nth(3)).toBeFocused();

  await page.emulateMedia({ forcedColors: 'active' });
  const glyphs = await actions.locator('svg').evaluateAll(nodes => nodes.map(node => {
    const box = node.getBoundingClientRect();
    return { width: box.width, height: box.height, transform: getComputedStyle(node).transform };
  }));
  expect(glyphs.every(glyph => glyph.width > 0 && glyph.height > 0)).toBe(true);
  expect(glyphs.every(glyph => glyph.transform === 'none')).toBe(true);
  await page.emulateMedia({ forcedColors: 'none' });

  for (const [locale, label] of [['zh-cmn-Hans-CN', '赞 · 2 个赞'], ['zh-cmn-Hant-TW', '按讚 · 2 個讚']]) {
    await page.addInitScript(value => localStorage.setItem('commune.locale', value), locale);
    await page.goto('/posts/p1');
    await expect(page.locator('#main-heading')).toBeVisible();
    await expect(page.getByRole('article').locator('.post-actions .icon-button').first()).toHaveAttribute('title', label);
  }
});

test('failed upload retains editor content and reports the failure', async ({ page }) => {
  const state = fixtures();
  state.mediaStatus = 400;
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1/new');
  await page.getByLabel('Topic title').fill('Stable draft');
  await page.getByLabel('Message').fill('Unsaved body');
  await page.locator('#editor-file').setInputFiles({ name: 'bad.png', mimeType: 'image/png', buffer: Buffer.from([1, 2]) });
  await expect(page.getByText('Upload failed. Your message is preserved.')).toBeVisible();
  await expect(page.getByLabel('Topic title')).toHaveValue('Stable draft');
  await expect(page.getByLabel('Message')).toHaveValue('Unsaved body');
});

test('reads notifications and performs community management', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/notifications');
  await expect(page.getByText(/replied to your post/)).toBeVisible();
  await page.getByRole('button', { name: 'Mark read' }).click();
  await page.getByRole('button', { name: 'Mark this snapshot read' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/notifications/read-all')).toBe(true);
  const readAll = state.calls.find(call => call.path === '/api/v1/notifications/read-all');
  expect(readAll.body.through_cursor).toBe('2026-10-20T08:30:00Z|1');

  await page.goto('/communities/c1/manage');
  await expect(page.getByRole('heading', { name: 'Manage community' })).toBeVisible();
  await page.getByLabel('Actor URI').fill('https://forum.test/users/bob');
  await page.getByRole('button', { name: 'Add member' }).click();
  await page.getByRole('button', { name: 'Add manager' }).click();
  await page.getByLabel('Who can read').selectOption('members');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await page.getByLabel('Post ID').fill('p1');
  await page.getByRole('button', { name: 'Remove post' }).click();
  await page.getByRole('button', { name: 'Accept submission' }).click();
  await expect.poll(() => state.calls.some(call => call.path.endsWith('/submissions'))).toBe(true);
  await expect.poll(() => state.calls.some(call => call.path.endsWith('/policy'))).toBe(true);
  await expect.poll(() => state.calls.some(call => call.path.endsWith('/managers'))).toBe(true);
});

test('manager authority is shown without implying posting membership', async ({ page }) => {
  const state = fixtures();
  state.communities[0] = {
    ...state.communities[0],
    viewer: { is_member: false, is_creator: false, is_manager: true, management_scope: 'site' },
    permissions: { can_post: false, can_manage: true, can_manage_members: true, can_manage_managers: true }
  };
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1');
  await expect(page.getByRole('link', { name: 'Manage community' })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Publish topic' })).toHaveCount(0);
});

test('sends each documented management action through its endpoint', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1/manage');
  await page.getByLabel('Post ID').fill('p1');
  for (const name of ['Remove post', 'Restore post', 'Hide on this site', 'Unhide on this site', 'Record site reception', 'Reject submission']) {
    await page.getByRole('button', { name, exact: true }).click();
    await page.waitForTimeout(50);
  }
  await page.getByLabel('Context ID').fill('ctx1');
  await page.getByRole('button', { name: 'Backfill context' }).click();
  await expect.poll(() => state.calls.filter(call => call.path.includes('/posts/p1/') || call.path.includes('/removals') || call.path.includes('/submissions') || call.path.includes('/backfill')).length).toBeGreaterThanOrEqual(7);
});

test('rich content strips executable markup and keeps safe links', async ({ page }) => {
  const state = fixtures();
  state.posts.p1.body_html = '<p>Safe body</p><script>window.__communePwned=1</script><a href="javascript:alert(1)">bad</a><a href="https://example.test/page">good</a><img src="https://images.example/p.png" alt="Remote image">';
  await mockApi(page, state, { authenticated: true });
  await open(page, '/posts/p1');
  await expect(page.getByText('Safe body')).toBeVisible();
  await expect(page.locator('a[href^="javascript"]')).toHaveCount(0);
  await expect(page.locator('img[alt="Remote image"]')).toHaveAttribute('referrerpolicy', 'no-referrer');
  expect(await page.evaluate(() => window.__communePwned)).toBeUndefined();
});

test('supports enlarged text and WCAG text spacing without overflow', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/posts/p1');
  await page.addStyleTag({ content: 'html { font-size: 200%; } * { line-height: 1.5 !important; letter-spacing: 0.12em !important; word-spacing: 0.16em !important; } p { margin-block-end: 2em !important; }' });
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
  expect(overflow).toBe(false);
});

test('community creation, search and management pages have no axe violations', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  for (const path of ['/', '/communities', '/communities/c1', '/posts/p1', '/search?kind=posts&q=Hello', '/notifications', '/profiles/alice', '/settings/profile', '/communities/c1/manage', '/communities/new', '/communities/c1/new', '/posts/p1/edit', '/login', '/register']) {
    await open(page, path);
    const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
    expect(results.violations, path + ': ' + JSON.stringify(results.violations, null, 2)).toEqual([]);
  }
});

test('mobile navigation dialog contains focus and restores it', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.setViewportSize({ width: 320, height: 800 });
  await open(page, '/');
  await page.getByRole('button', { name: 'Open navigation' }).click();
  const drawer = page.getByRole('dialog', { name: 'Main navigation' });
  await expect(drawer).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(drawer).toBeHidden();
  await expect(page.getByRole('button', { name: 'Open navigation' })).toBeFocused();
});

for (const [status, message] of [
  [400, 'Check your input and try again.'],
  [401, 'Your session has expired. Please log in again.'],
  [403, 'This action is not allowed, or your access has changed.'],
  [404, 'This content is unavailable.'],
  [409, 'This content changed. Your draft is safe; compare the latest source.'],
  [429, 'Too many requests. Please wait and try again.'],
  [503, 'This service is temporarily unavailable.']
]) {
  test('maps HTTP ' + status + ' to a localized failure', async ({ page }) => {
    const state = fixtures();
    await mockApi(page, state, { authenticated: true });
    await page.route('**/api/v1/topics?*', route => json(route, status, { error: 'failure' }));
    await open(page, '/');
    await expect(page.getByText(message).first()).toBeVisible();
  });
}

test('maps network failures without treating them as successful data', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.route('**/api/v1/topics?*', route => route.abort());
  await open(page, '/');
  await expect(page.getByText('Could not connect. Check your connection and try again.')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Try again' })).toBeVisible();
});

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
    follow_policy: 'open', follower_count: 4,
    host_site_id: 'a',
    viewer: { is_member: true, is_creator: true, is_manager: true, management_scope: 'community', is_following: true, follow_state: 'accepted', can_follow: false },
    permissions: { can_post: true, can_manage: true, can_manage_members: true, can_manage_managers: true }
  };
  const topic = {
    id: 'p1', community_id: 'c1', object_type: 'Page', title: 'Hello world', body: 'Hello',
    body_html: '<p>Hello <strong>world</strong></p><p dir="auto">مرحبا — नमस्ते — สวัสดี — 你好 — é — 👩‍💻</p>', author_actor_uri: identity.actor_uri,
    author: { acct: 'alice@forum.test', display_name: 'Alice' },
    authored_at: '2026-10-20T08:30:00Z', version: 4, content_format: 'markdown',
    like_count: 2, liked_by_me: false, score: 2, upvotes: 2, downvotes: 0, voted_by_me: 0,
    saved_by_me: false, read_by_me: false, hidden_by_me: false,
    reply_count: 1, deleted: false,
    permissions: { can_edit: true, can_delete: true, can_like: true, can_vote: true, can_upvote: true, can_downvote: true, can_reply: true, can_hide: true, can_save: true, can_hide_for_me: true, can_moderate: true },
    attachments: [{ url: '/api/v1/media/file1', media_type: 'application/pdf', name: 'notes.pdf' }]
  };
  const reply = {
    ...topic, id: 'r1', object_type: 'Note', title: '', body: 'A reply', body_html: '<p>A reply</p>',
    parent_id: 'p1', reply_count: 1,
    permissions: { ...topic.permissions, can_edit: false, can_delete: false }
  };
  const nestedReply = { ...reply, id: 'r1r1', body: 'Nested answer', body_html: '<p>Nested answer</p>', parent_id: 'r1', reply_count: 0 };
  const replyThread = { ...reply, depth: 1, child_count: 1, children: [nestedReply] };
  return {
    signedIn: false,
    posts: { p1: topic },
    replies: { p1: [replyThread], r1: [nestedReply] },
    communities: [community],
    reports: [{ id: 'report1', target_kind: 'post', target_id: 'p1', reason: 'spam', state: 'open', resolution_note: '', created_at: '2026-10-20T08:30:00Z' }],
    modlog: [{ id: 'log1', action: 'ban-site', actor_actor_uri: identity.actor_uri, target_kind: 'person', target_id: 'https://forum.test/users/bob', reason: 'spam', created_at: '2026-10-20T08:30:00Z' }],
    blocks: [],
    calls: [],
    likes: new Map(),
    conflictOnce: false,
    loginStatus: 200,
    mediaStatus: 201,
    mentionStatus: 200,
    voteDelay: 0,
    unreadCount: 2
  };
}

function json(route, status, body) {
  return route.fulfill({ status, contentType: 'application/json; charset=utf-8', body: JSON.stringify(body) });
}

function pageOf(items, limit = 20, offset = 0) {
  return { items, limit, offset };
}

async function mockApi(page, state, { authenticated = false, identity: responseIdentity = identity } = {}) {
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
      return state.signedIn ? json(route, 200, responseIdentity) : json(route, 401, { error: 'unauthenticated' });
    }
    if (path === '/api/v1/auth/login' && method === 'POST') {
      if (state.loginStatus !== 200) return json(route, state.loginStatus, { error: 'invalid credentials' });
      state.signedIn = true;
      return json(route, 200, responseIdentity);
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
      return json(route, 200, { count: state.unreadCount });
    }
    if (path === '/api/v1/notifications' && method === 'GET') {
      return json(route, 200, { items: [{ id: 1, kind: 'reply', post_id: 'p1', actor_uri: 'https://forum.test/users/bob', created_at: '2026-10-20T08:30:00Z', read: false }], limit: 20, offset: 0, through_cursor: '2026-10-20T08:30:00Z|1' });
    }
    if (path === '/api/v1/notifications/1/read' || path === '/api/v1/notifications/read-all') {
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/auth/password/reset' && method === 'POST') {
      return route.fulfill({ status: 202 });
    }
    if (path === '/api/v1/auth/password/reset/confirm' && method === 'POST') {
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/auth/password/change' && method === 'POST') {
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/site/vote-settings' && method === 'GET') {
      return json(route, 200, { upvotes_enabled: true, downvotes_enabled: true });
    }
    if (path === '/api/v1/mentions/candidates' && method === 'GET') {
      if (state.mentionStatus !== 200) return json(route, state.mentionStatus, { error: 'unavailable' });
      const query = (url.searchParams.get('q') || '').toLowerCase();
      const items = [
        { actor_uri: 'https://forum.test/users/bob', acct: 'bob@forum.test', display_name: 'Bob', avatar: '' },
        { actor_uri: 'https://remote.test/users/carol', acct: 'carol@remote.test', display_name: 'Carol', avatar: '' }
      ].filter(item => item.acct.toLowerCase().includes(query) || item.display_name.toLowerCase().includes(query));
      return json(route, 200, { items });
    }
    if (path === '/api/v1/admin/vote-settings' && method === 'PUT') {
      return json(route, 200, { upvotes_enabled: body.upvotes_enabled, downvotes_enabled: body.downvotes_enabled });
    }
    if (path === '/api/v1/reports' && method === 'GET') {
      return json(route, 200, pageOf(state.reports));
    }
    if (path === '/api/v1/reports' && method === 'POST') {
      return route.fulfill({ status: 201 });
    }
    if (path.startsWith('/api/v1/reports/') && path.endsWith('/resolve') && method === 'POST') {
      const id = path.split('/')[4];
      state.reports = state.reports.map(report => report.id === id ? { ...report, state: body.state, resolution_note: body.note || '' } : report);
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/modlog' && method === 'GET') {
      return json(route, 200, pageOf(state.modlog));
    }
    if (path === '/api/v1/admin/bans' && (method === 'POST' || method === 'DELETE')) {
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/account/blocks' && method === 'GET') {
      return json(route, 200, { items: state.blocks });
    }
    if (path === '/api/v1/account/blocks' && (method === 'POST' || method === 'DELETE')) {
      if (method === 'POST') {
        state.blocks.push({ kind: body.kind, target: body.target, created_at: '2026-10-20T08:30:00Z' });
      } else {
        state.blocks = state.blocks.filter(block => block.kind !== body.kind || block.target !== body.target);
      }
      return route.fulfill({ status: 204 });
    }
    if (path.startsWith('/api/v1/account/') && method === 'GET') {
      return json(route, 200, pageOf(Object.values(state.posts)));
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
    if (path === '/api/v1/communities/c1/follow' && (method === 'POST' || method === 'DELETE')) {
      state.communities[0].viewer.is_following = method === 'POST';
      state.communities[0].viewer.follow_state = method === 'POST' ? 'accepted' : 'undone';
      state.communities[0].viewer.can_follow = method !== 'POST';
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/communities/c1/follow-requests' && method === 'GET') {
      return json(route, 200, pageOf([{ actor_uri: 'https://forum.test/users/bob', updated_at: '2026-10-20T08:30:00Z' }]));
    }
    if (path.startsWith('/api/v1/communities/c1/follow-requests/') && method === 'POST') {
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v1/communities/c1/bans' && (method === 'POST' || method === 'DELETE')) {
      return route.fulfill({ status: 204 });
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
      const id = path.split('/')[4];
      const post = state.posts[id];
      if (post) {
        post.liked_by_me = method === 'POST';
        post.voted_by_me = method === 'POST' ? 1 : 0;
        post.upvotes = Math.max(0, (post.upvotes || 0) + (method === 'POST' ? 1 : -1));
        post.like_count = post.upvotes;
        post.score = post.upvotes - (post.downvotes || 0);
      }
      return route.fulfill({ status: 204 });
    }
    if (path.startsWith('/api/v1/posts/') && path.endsWith('/vote')) {
      if (state.voteDelay) await new Promise(resolve => setTimeout(resolve, state.voteDelay));
      const id = path.split('/')[4];
      const post = state.posts[id];
      if (post) {
        const previous = post.voted_by_me || 0;
        if (previous === 1) post.upvotes = Math.max(0, post.upvotes - 1);
        if (previous === -1) post.downvotes = Math.max(0, post.downvotes - 1);
        if (body.score === 1) post.upvotes += 1;
        if (body.score === -1) post.downvotes += 1;
        post.voted_by_me = body.score;
        post.liked_by_me = body.score === 1;
        post.like_count = post.upvotes;
        post.score = post.upvotes - post.downvotes;
      }
      return route.fulfill({ status: 204 });
    }
    if (path.startsWith('/api/v1/posts/') && path.endsWith('/save')) {
      const id = path.split('/')[4];
      if (state.posts[id]) state.posts[id].saved_by_me = method === 'POST';
      return route.fulfill({ status: 204 });
    }
    if (path.startsWith('/api/v1/posts/') && path.endsWith('/read')) {
      const id = path.split('/')[4];
      if (state.posts[id]) state.posts[id].read_by_me = true;
      return route.fulfill({ status: 204 });
    }
    if (path.startsWith('/api/v1/posts/') && path.endsWith('/hide-for-me')) {
      const id = path.split('/')[4];
      if (state.posts[id]) state.posts[id].hidden_by_me = method === 'POST';
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
  expect(state.calls.some(call => call.path === '/api/v1/posts/r1/replies')).toBe(false);
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
  await expect(page.locator('#navigation-drawer')).toContainText('@alice');

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
  await expect(page.locator('#navigation-drawer')).toContainText('@alice');
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
  await expect(page.locator('#navigation-drawer')).toContainText('@alice');
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
  await expect(page.locator('#navigation-drawer')).toContainText('@alice');
  await page.getByRole('button', { name: 'Log out' }).click();
  await expect(page.getByLabel('Username or email')).toBeVisible();
  const response = page.waitForResponse('**/api/v1/auth/session');
  await json(pending, 200, identity);
  await (await response).finished();
  await page.waitForTimeout(100);
  await expect(page.getByLabel('Username or email')).toBeVisible();
  await expect(page.locator('#navigation-drawer')).not.toContainText('@alice');
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
  await expect(page.locator('#navigation-drawer')).not.toContainText('@alice');
  await expect(page.getByLabel('Display name')).toHaveCount(0);
  await page.unroute('**/api/v1/topics?*');
  await page.unroute('**/api/v1/profile');
  // Keep the next profile read from replacing the cleared form with server values.
  await page.route('**/api/v1/profile', route => json(route, 503, { error: 'temporarily unavailable' }));
  await page.getByRole('link', { name: 'Log in', exact: true }).first().click();
  await page.getByLabel('Username or email').fill('alice');
  await page.getByLabel('Password').fill('long-enough-password');
  await page.getByRole('button', { name: 'Log in' }).click();
  await expect(page.locator('#navigation-drawer')).toContainText('@alice');
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

test('upvotes, deletes with accessible confirmation, and updates profile', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/posts/p1');
  const topicCard = page.getByRole('article', { name: 'Hello world' });
  await expect(topicCard.getByRole('button', { name: /^Upvote/ })).toHaveAttribute('aria-pressed', 'false');
  await topicCard.getByRole('button', { name: /^Upvote/ }).click();
  const clearVote = topicCard.getByRole('button', { name: /^Clear vote/ });
  await expect(clearVote).toBeVisible();
  await expect(clearVote).toHaveAttribute('aria-pressed', 'true');

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

test('votes, saves, hides and reports posts through the documented endpoints', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/posts/p1');

  const topicCard = page.getByRole('article', { name: 'Hello world' });
  await topicCard.getByRole('button', { name: /^Upvote/ }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/posts/p1/vote' && call.body.score === 1)).toBe(true);
  await topicCard.getByRole('button', { name: /^Clear vote/ }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/posts/p1/vote' && call.body.score === 0)).toBe(true);
  await topicCard.getByRole('button', { name: /^Downvote/ }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/posts/p1/vote' && call.body.score === -1)).toBe(true);
  await expect(topicCard.getByRole('button', { name: /^Clear vote/ })).toHaveAttribute('aria-pressed', 'true');

  await topicCard.getByRole('button', { name: 'Save post' }).click();
  await expect(topicCard.getByRole('button', { name: 'Remove from saved' })).toHaveAttribute('aria-pressed', 'true');

  await topicCard.getByRole('button', { name: 'Hide for me' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/posts/p1/hide-for-me')).toBe(true);

  await topicCard.getByRole('button', { name: 'Report post' }).click();
  const dialog = page.getByRole('dialog', { name: 'Report content' });
  await expect(dialog).toBeVisible();
  await dialog.getByLabel('Reason').fill('spam');
  await dialog.getByRole('button', { name: 'Submit report' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/reports' && call.body.target_id === 'p1')).toBe(true);
  await expect(dialog).toBeHidden();
});

test('loads threaded replies with URL-backed sort and depth', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/posts/p1?sort=top&max_depth=2');
  const replyCall = state.calls.find(call => call.path === '/api/v1/posts/p1/replies');
  expect(replyCall.search).toContain('sort=top');
  expect(replyCall.search).toContain('max_depth=2');
  await page.getByLabel('Reply order').selectOption('new');
  await expect(page).toHaveURL(/sort=new/);
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/posts/p1/replies' && call.search.includes('sort=new'))).toBe(true);
});

test('follows communities and manages personal blocks and account content', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1');
  await page.getByRole('button', { name: 'Unfollow' }).click();
  await expect(page.getByRole('button', { name: 'Follow', exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Follow', exact: true }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/communities/c1/follow')).toBe(true);

  await page.goto('/account/saved');
  await expect(page.getByRole('link', { name: 'Hello world' })).toBeVisible();
  await page.goto('/account/blocks');
  await page.getByLabel('Target').fill('https://forum.test/users/bob');
  await page.getByRole('button', { name: 'Add block' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/account/blocks' && call.method === 'POST')).toBe(true);
  await expect(page.getByText('https://forum.test/users/bob')).toBeVisible();
  await page.getByRole('button', { name: 'Remove block' }).click();
  await page.getByRole('dialog', { name: 'Personal blocks' }).getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/account/blocks' && call.method === 'DELETE')).toBe(true);
});

test('removes saved and hidden state from account collections', async ({ page }) => {
  const state = fixtures();
  state.posts.p1.saved_by_me = true;
  state.posts.p1.hidden_by_me = true;
  await mockApi(page, state, { authenticated: true });

  await open(page, '/account/saved');
  await page.getByRole('button', { name: 'Remove from saved' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/posts/p1/save' && call.method === 'DELETE')).toBe(true);

  await page.goto('/account/hidden');
  await page.getByRole('button', { name: 'Unhide for me' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/posts/p1/hide-for-me' && call.method === 'DELETE')).toBe(true);
});

test('resets and changes passwords with fragment-token handling', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/reset-password');
  await page.getByLabel('Email').fill('alice@example.org');
  await page.getByRole('button', { name: 'Send reset link' }).click();
  await expect(page.getByText(/Check your email for the reset link/)).toBeVisible();

  await page.goto('/reset-password/confirm#token=reset-token');
  await expect(page).toHaveURL(/\/reset-password\/confirm$/);
  await page.getByLabel('New password').fill('new-password');
  await page.getByRole('button', { name: 'Set new password' }).click();
  await expect(page).toHaveURL(/\/login$/);

  await page.goto('/settings/password');
  await page.getByLabel('Current password').fill('old-password');
  await page.getByLabel('New password').fill('new-password');
  await page.getByRole('button', { name: 'Change password' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/auth/password/change')).toBe(true);
  await expect(page.getByText('Password changed. Other sessions were revoked.')).toBeVisible();
});

test('operates the current-site administration center', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/settings');
  await page.getByLabel('Downvotes enabled').uncheck();
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/admin/vote-settings' && call.body.downvotes_enabled === false)).toBe(true);

  await page.goto('/admin/reports');
  await page.getByLabel('Resolution note').fill('handled');
  await page.getByRole('button', { name: 'Resolve', exact: true }).click();
  await page.getByRole('dialog', { name: 'Report resolution' }).getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/reports/report1/resolve')).toBe(true);

  await page.goto('/admin/modlog');
  await expect(page.getByText('ban-site')).toBeVisible();

  await page.goto('/admin/bans');
  await page.locator('#ban-actor').fill('https://forum.test/users/bob');
  await page.locator('#ban-reason').fill('spam');
  await page.getByRole('button', { name: 'Create ban' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/admin/bans' && call.method === 'POST')).toBe(true);
});

test('denies current-site administration to ordinary accounts without management reads', async ({ page }) => {
  const state = fixtures();
  const ordinary = { ...identity, roles: { site_administrator: false, deployment_superadministrator: false } };
  await mockApi(page, state, { authenticated: true, identity: ordinary });
  await open(page, '/admin');
  await expect(page.getByText('This action is not allowed, or your access has changed.')).toBeVisible();
  expect(state.calls.some(call => call.path === '/api/v1/site/vote-settings' || call.path === '/api/v1/reports' || call.path === '/api/v1/modlog')).toBe(false);
});

test('cancels a management confirmation with Escape and restores focus', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/bans');
  const removeBan = page.getByRole('button', { name: 'Remove ban' });
  await removeBan.click();
  await expect(page.getByRole('dialog', { name: 'Site ban' })).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(page.getByRole('dialog', { name: 'Site ban' })).toBeHidden();
  await expect(removeBan).toBeFocused();
});

test('post action icons stay inside the card with localized tooltips and focus order', async ({ page }) => {
  const state = fixtures();
  state.posts.p1.reply_count = 3;
  await mockApi(page, state, { authenticated: true });
  await page.setViewportSize({ width: 320, height: 800 });
  await open(page, '/posts/p1');

  const card = page.getByRole('article', { name: 'Hello world' });
  const actions = card.locator('.post-actions .icon-button');
  await expect(actions).toHaveCount(8);

  const boxes = await actions.evaluateAll(nodes => nodes.map(node => {
    const box = node.getBoundingClientRect();
    return { left: box.left, right: box.right, top: box.top, bottom: box.bottom };
  }));
  for (let index = 0; index < boxes.length; index += 1) {
    for (let other = index + 1; other < boxes.length; other += 1) {
      const overlaps = boxes[index].left < boxes[other].right && boxes[index].right > boxes[other].left && boxes[index].top < boxes[other].bottom && boxes[index].bottom > boxes[other].top;
      expect(overlaps).toBe(false);
    }
  }

  const voteBoxes = await card.locator('.vote-control').evaluate(node => {
    const score = node.querySelector('.vote-score').getBoundingClientRect();
    const buttons = [...node.querySelectorAll('.vote-button')].map(button => button.getBoundingClientRect());
    return { score, buttons };
  });
  expect(voteBoxes.buttons.length).toBe(2);
  expect(voteBoxes.score.left).toBeGreaterThanOrEqual(voteBoxes.buttons[0].right);
  expect(voteBoxes.score.right).toBeLessThanOrEqual(voteBoxes.buttons[1].left);
  expect(Math.abs(voteBoxes.score.top - voteBoxes.buttons[0].top)).toBeLessThanOrEqual(4);

  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(0);

  await expect(actions.nth(0)).toHaveAttribute('title', 'Upvote · Score 2');
  await expect(actions.nth(1)).toHaveAttribute('title', 'Downvote · Score 2');
  await expect(actions.nth(2)).toHaveAttribute('title', 'Save post');
  await expect(actions.nth(3)).toHaveAttribute('title', 'Hide for me');
  await expect(actions.nth(4)).toHaveAttribute('title', 'Report post');
  await expect(actions.nth(5)).toHaveAttribute('title', 'Edit post');
  await expect(actions.nth(6)).toHaveAttribute('title', 'Delete post');
  await expect(actions.nth(7)).toHaveAttribute('title', '3 replies');
  await expect(card.locator('.vote-score')).toHaveText('2');
  await expect(actions.nth(7).locator('.action-count')).toHaveText('3');
  await expect(card.getByRole('button', { name: 'Upvote · Score 2' })).toBeVisible();
  await expect(card.getByRole('button', { name: '3 replies' })).toBeVisible();

  await actions.nth(0).focus();
  for (let index = 1; index < 8; index += 1) {
    await page.keyboard.press('Tab');
    await expect(actions.nth(index)).toBeFocused();
  }

  await page.emulateMedia({ forcedColors: 'active' });
  const glyphs = await actions.locator('svg').evaluateAll(nodes => nodes.map(node => {
    const box = node.getBoundingClientRect();
    return { width: box.width, height: box.height, transform: getComputedStyle(node).transform };
  }));
  expect(glyphs.every(glyph => glyph.width > 0 && glyph.height > 0)).toBe(true);
  expect(glyphs.every(glyph => glyph.transform === 'none')).toBe(true);
  await page.emulateMedia({ forcedColors: 'none' });

  for (const [locale, label] of [['zh-cmn-Hans-CN', '赞成 · 得分 2'], ['zh-cmn-Hant-TW', '贊成 · 得分 2']]) {
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

test('authors Markdown with toolbar formatting and complete mention handles', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1/new');
  const message = page.getByLabel('Message');

  await message.fill('hello');
  await message.evaluate(element => {
    element.focus();
    element.setSelectionRange(0, 5);
    element.dispatchEvent(new Event('select', { bubbles: true }));
  });
  await page.getByRole('button', { name: 'Bold' }).click();
  await expect(message).toHaveValue('**hello**');

  await message.fill('Hello @bo');
  await expect(page.getByRole('option', { name: /Bob/ })).toBeVisible();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/mentions/candidates' && call.search.includes('q=bo'))).toBe(true);
  await message.evaluate(element => element.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, cancelable: true, isComposing: true })));
  await expect(message).toHaveValue('Hello @bo');
  await expect(page.locator('.mention-option')).toHaveCount(1);
  await message.press('Enter');
  await expect(message).toHaveValue('Hello @bob@forum.test ');
  await expect(page.locator('.mention-option')).toHaveCount(0);

  await page.setViewportSize({ width: 320, height: 800 });
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
  expect(overflow).toBe(false);
});

test('edits a profile biography with Markdown mention insertion', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/settings/profile');
  const biography = page.getByLabel(/Biography/);

  await biography.fill('About @bo');
  await expect(page.getByRole('option', { name: /Bob/ })).toBeVisible();
  await biography.press('Enter');
  await expect(biography).toHaveValue('About @bob@forum.test ');
  await page.getByRole('button', { name: 'Save profile' }).click();
  await expect.poll(() => state.calls.some(call => call.method === 'PATCH' && call.path === '/api/v1/profile' && call.body.biography === 'About @bob@forum.test ')).toBe(true);
});

test('inserts stored remote mention handles', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1/new');
  const message = page.getByLabel('Message');
  await message.fill('Hello @ca');
  await expect(page.getByRole('option', { name: /Carol/ })).toBeVisible();
  await message.press('Enter');
  await expect(message).toHaveValue('Hello @carol@remote.test ');
});

test('empty mention results do not block publishing', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1/new');
  const message = page.getByLabel('Message');
  await page.getByLabel('Topic title').fill('No matching accounts');
  await message.fill('Hello @zz');
  await expect(page.locator('.mention-list .mention-status')).toContainText('No matching accounts');
  await page.getByRole('button', { name: 'Publish topic' }).click();
  await expect(page).toHaveURL(/\/posts\/p-new$/);
});

test('mention lookup failure is non-blocking', async ({ page }) => {
  const state = fixtures();
  state.mentionStatus = 503;
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1/new');
  const message = page.getByLabel('Message');

  await page.getByLabel('Topic title').fill('Unavailable mentions');
  await message.fill('Hello @bo');
  await expect(page.locator('.mention-list .mention-status')).toContainText('Mention suggestions are unavailable');
  await expect(message).toHaveValue('Hello @bo');
  await page.getByRole('button', { name: 'Publish topic' }).click();
  await expect(page).toHaveURL(/\/posts\/p-new$/);
});

test('keeps localized timestamps after refresh and locale switch', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/posts/p1');
  const stamp = page.locator('time[data-commune-time]').first();
  await expect(stamp).not.toHaveText(/^2026-\d/);
  const before = await stamp.textContent();
  expect(before).not.toMatch(/ago/);

  const card = page.getByRole('article', { name: 'Hello world' });
  await card.getByRole('button', { name: /^Upvote/ }).click();
  await expect(stamp).toHaveText(before);

  await page.getByLabel('Language').selectOption('zh-cmn-Hans-CN');
  await expect(stamp).toHaveText(/2026/);
  await expect(stamp).not.toHaveText(/^2026-\d/);
});

test('compacts section headings and keeps entity headings distinct', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/');
  const sectionSize = await page.locator('#main-heading').evaluate(element => parseFloat(getComputedStyle(element).fontSize));
  expect(sectionSize).toBeLessThanOrEqual(28);

  await page.goto('/posts/p1');
  const entitySize = await page.locator('#main-heading').evaluate(element => parseFloat(getComputedStyle(element).fontSize));
  expect(entitySize).toBeGreaterThan(sectionSize);
  expect(entitySize).toBeLessThanOrEqual(36);

  await page.setViewportSize({ width: 320, height: 800 });
  await page.goto('/');
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
  expect(overflow).toBe(false);
});

test('clears an existing vote when its direction is disabled', async ({ page }) => {
  const state = fixtures();
  state.posts.p1.permissions.can_downvote = false;
  state.posts.p1.voted_by_me = -1;
  state.posts.p1.downvotes = 1;
  state.posts.p1.score = 1;
  await mockApi(page, state, { authenticated: true });
  await open(page, '/posts/p1');
  const card = page.getByRole('article', { name: 'Hello world' });
  await card.getByRole('button', { name: /^Clear vote/ }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/posts/p1/vote' && call.body.score === 0)).toBe(true);
  await expect(card.getByRole('button', { name: /^Downvote/ })).toHaveCount(0);
});

test('disables both vote directions while a vote is in flight', async ({ page }) => {
  const state = fixtures();
  state.voteDelay = 500;
  await mockApi(page, state, { authenticated: true });
  await open(page, '/posts/p1');
  const card = page.getByRole('article', { name: 'Hello world' });
  const upvote = card.getByRole('button', { name: /^Upvote/ });
  const downvote = card.getByRole('button', { name: /^Downvote/ });
  await upvote.click();
  await expect(upvote).toBeDisabled();
  await expect(downvote).toBeDisabled();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/posts/p1/vote')).toBe(true);
  await expect(card.getByRole('button', { name: /^Clear vote/ })).toBeVisible();
});

test('reads notifications and performs community management', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/notifications');
  await expect(page.locator('.drawer-badge')).toHaveText('2');
  await expect(page.locator('.drawer-badge')).toHaveCSS('background-color', 'rgb(186, 26, 26)');
  await expect(page.getByText(/replied to your post/)).toBeVisible();
  await page.getByRole('button', { name: 'Mark read' }).click();
  await page.getByRole('button', { name: 'Mark this snapshot read' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/notifications/read-all')).toBe(true);
  const readAll = state.calls.find(call => call.path === '/api/v1/notifications/read-all');
  expect(readAll.body.through_cursor).toBe('2026-10-20T08:30:00Z|1');

  await page.goto('/communities/c1/manage');
  await expect(page.getByRole('heading', { name: 'Manage community' })).toBeVisible();
  await page.locator('#manage-actor').fill('https://forum.test/users/bob');
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

test('keeps a zero unread badge neutral and matches notification action typography', async ({ page }) => {
  const state = fixtures();
  state.unreadCount = 0;
  await mockApi(page, state, { authenticated: true });
  await open(page, '/notifications');

  const badge = page.getByRole('link', { name: 'Notifications (0)' }).locator('.drawer-badge');
  await expect(badge).toHaveText('0');
  await expect(badge).toHaveCSS('background-color', 'rgb(236, 231, 242)');
  await expect(badge).toHaveCSS('color', 'rgb(73, 70, 79)');

  const summary = page.locator('.notification-unread-summary');
  const readAction = page.getByRole('button', { name: 'Mark this snapshot read' });
  await expect(summary).toBeVisible();
  await expect(summary).toHaveCSS('border-top-style', 'none');
  const [summarySize, actionSize] = await Promise.all([
    summary.evaluate(element => getComputedStyle(element).fontSize),
    readAction.evaluate(element => getComputedStyle(element).fontSize)
  ]);
  expect(summarySize).toBe(actionSize);
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

test('handles community follow requests, reports, history and bans', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1/manage');

  await page.getByRole('button', { name: 'Accept', exact: true }).click();
  await expect.poll(() => state.calls.some(call => call.path.includes('/follow-requests/'))).toBe(true);

  await page.getByLabel('Resolution note').fill('reviewed');
  await page.getByRole('button', { name: 'Resolve', exact: true }).click();
  await page.getByRole('dialog', { name: 'Report resolution' }).getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/reports/report1/resolve')).toBe(true);

  await expect(page.getByText('ban-site').first()).toBeVisible();
  await page.locator('#community-ban-actor').fill('https://forum.test/users/bob');
  await page.locator('#community-ban-reason').fill('spam');
  await page.getByRole('button', { name: 'Create ban' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v1/communities/c1/bans' && call.method === 'POST')).toBe(true);
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
  test.setTimeout(120000);
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  const paths = [
    '/', '/communities', '/communities/c1', '/posts/p1',
    '/search?kind=posts&q=Hello', '/notifications', '/profiles/alice',
    '/settings/profile', '/settings/password', '/communities/c1/manage',
    '/communities/new', '/communities/c1/new', '/posts/p1/edit',
    '/login', '/register', '/reset-password', '/reset-password/confirm',
    '/account/saved', '/account/read', '/account/hidden', '/account/liked',
    '/account/blocks', '/admin', '/admin/settings', '/admin/reports',
    '/admin/modlog', '/admin/bans'
  ];
  for (const width of [1280, 768, 320]) {
    await page.setViewportSize({ width, height: 800 });
    for (const path of paths) {
      await open(page, path);
      const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
      expect(results.violations, width + 'px ' + path + ': ' + JSON.stringify(results.violations, null, 2)).toEqual([]);
    }
  }
});

test('authoring toolbar and open mention list have no axe violations', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/communities/c1/new');
  await page.getByLabel('Message').fill('Hello @bo');
  await expect(page.getByRole('option', { name: /Bob/ })).toBeVisible();
  const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
  expect(results.violations, JSON.stringify(results.violations, null, 2)).toEqual([]);
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

test('wide navigation drawer follows document tab order without trapping focus', async ({ page }) => {
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/');

  await page.locator('.skip-link').focus();
  await expect(page.getByRole('link', { name: 'Skip to main content' })).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(page.getByRole('button', { name: 'Close navigation' })).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Commune' })).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Latest discussions' })).toBeFocused();
  await page.keyboard.press('Shift+Tab');
  await expect(page.getByRole('link', { name: 'Commune' })).toBeFocused();
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

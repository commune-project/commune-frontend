import assert from 'node:assert/strict';
import test from 'node:test';
import { formatTime, formattingLocale, normalizeResponse, pluralCategory, readPreference, savePreference } from '../src/bridge.js';

test('normalizes large revisions without rounding', () => {
  const value = normalizeResponse('{"version":9223372036854775807,"item":{"id":42}}');
  assert.equal(value.version, '9223372036854775807');
  assert.equal(value.item.id, '42');
});

test('maps catalog identities to interoperable Intl locales', () => {
  assert.equal(formattingLocale('en-US'), 'en-US');
  assert.equal(formattingLocale('zh-cmn-Hans-CN'), 'zh-Hans-CN');
  assert.equal(formattingLocale('zh-cmn-Hant-TW'), 'zh-Hant-TW');
  assert.equal(formattingLocale('unknown'), 'en-US');
});

test('uses browser plural categories', () => {
  assert.equal(pluralCategory('en-US', 1), 'one');
  assert.equal(pluralCategory('en-US', 2), 'other');
  assert.equal(pluralCategory('zh-cmn-Hans-CN', 1), 'other');
});

test('formats dates and relative times in the selected locale', () => {
  const english = formatTime('en-US', '2026-10-20T08:30:00Z', Date.parse('2026-10-20T09:30:00Z'));
  const traditional = formatTime('zh-cmn-Hant-TW', '2026-10-20T08:30:00Z', Date.parse('2026-10-20T09:30:00Z'));
  assert.match(english.absolute, /2026/);
  assert.match(english.relative, /hour/);
  assert.match(traditional.relative, /小時|小時|小時/);
});

test('returns safe values for invalid dates', () => {
  const result = formatTime('en-US', 'not-a-date');
  assert.equal(result.absolute, 'not-a-date');
  assert.equal(result.relative, 'not-a-date');
});

test('survives unavailable preference storage', () => {
  const storage = { getItem() { throw new Error('denied'); }, setItem() { throw new Error('denied'); } };
  assert.equal(readPreference(storage), null);
  assert.doesNotThrow(() => savePreference(storage, 'en-US'));
});

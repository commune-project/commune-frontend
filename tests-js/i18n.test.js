import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { validateCatalogs } from '../scripts/i18n-validation.mjs';

const root = path.resolve('translations');
const readCatalogs = () => Object.fromEntries(
  fs.readdirSync(root).filter(name => name.endsWith('.ftl')).map(name => [name, fs.readFileSync(path.join(root, name), 'utf8')])
);

test('all three catalogs are complete and consistent', () => {
  assert.deepEqual(validateCatalogs(readCatalogs()), []);
});

test('a missing key is rejected', () => {
  const files = readCatalogs();
  files['messages.zh-cmn-Hans-CN.ftl'] = files['messages.zh-cmn-Hans-CN.ftl'].replace(/^nav-search\s*=.*\n/m, '');
  assert.match(validateCatalogs(files).join('\n'), /missing message nav-search/);
});

test('a placeholder mismatch is rejected', () => {
  const files = readCatalogs();
  files['messages.zh-cmn-Hant-TW.ftl'] = files['messages.zh-cmn-Hant-TW.ftl'].replace('replies-other = { $count }', 'replies-other = { $total }');
  assert.match(validateCatalogs(files).join('\n'), /placeholder mismatch for replies-other/);
});

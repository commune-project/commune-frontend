import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const generated = fs.readFileSync(path.resolve('src/Generated/I18n.elm'), 'utf8');
const locales = ['en-US', 'zh-cmn-Hans-CN', 'zh-cmn-Hant-TW'];

test('every generated accessor points to an existing content-addressed asset', () => {
  for (const locale of locales) {
    const escaped = locale.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const match = new RegExp(`messages\\.${escaped}\\.(\\d+)\\.json`).exec(generated);
    assert.ok(match, `missing hash for ${locale}`);
    const file = path.resolve('public/assets/i18n', `messages.${locale}.${match[1]}.json`);
    assert.ok(fs.existsSync(file), `${file} is missing`);
    const values = JSON.parse(fs.readFileSync(file, 'utf8'));
    assert.ok(values.includes(locale), `catalog identity missing for ${locale}`);
    assert.ok(values.every(value => typeof value === 'string'));
    assert.ok(values.every(value => !/https?:\/\//i.test(value)), 'catalogs must not depend on remote providers');
  }
});

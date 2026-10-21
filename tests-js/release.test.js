import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { stageRelease } from '../scripts/stage-release.mjs';

test('stages current assets and retains prior hashed catalogs', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'commune-release-'));
  const dist = path.join(root, 'dist');
  const previous = path.join(root, 'previous');
  const output = path.join(root, 'next');
  fs.mkdirSync(path.join(dist, 'assets', 'i18n'), { recursive: true });
  fs.mkdirSync(path.join(previous, 'assets', 'i18n'), { recursive: true });
  fs.writeFileSync(path.join(dist, 'index.html'), 'new');
  fs.writeFileSync(path.join(dist, 'assets', 'i18n', 'messages.en-US.2.json'), 'new');
  fs.writeFileSync(path.join(previous, 'assets', 'i18n', 'messages.en-US.1.json'), 'old');

  stageRelease(dist, output, previous);

  assert.equal(fs.readFileSync(path.join(output, 'index.html'), 'utf8'), 'new');
  assert.equal(fs.readFileSync(path.join(output, 'assets', 'i18n', 'messages.en-US.1.json'), 'utf8'), 'old');
  assert.equal(fs.readFileSync(path.join(output, 'assets', 'i18n', 'messages.en-US.2.json'), 'utf8'), 'new');
  fs.rmSync(root, { recursive: true, force: true });
});

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { validateCatalogs } from './i18n-validation.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const translationsDir = path.join(root, 'translations');
const files = Object.fromEntries(
  fs.readdirSync(translationsDir)
    .filter(name => name.endsWith('.ftl'))
    .map(name => [name, fs.readFileSync(path.join(translationsDir, name), 'utf8')])
);
const errors = validateCatalogs(files);
if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}

const temporaryElm = path.join(root, 'src', 'Generated', 'I18nCheck.elm');
const temporaryAssets = fs.mkdtempSync(path.join(os.tmpdir(), 'commune-i18n-'));
try {
  execFileSync(process.execPath, [
    path.join(root, 'node_modules', 'travelm-agency', 'index.js'),
    translationsDir,
    `--elm_path=${temporaryElm}`,
    `--json_path=${temporaryAssets}`,
    '--hash'
  ], { cwd: root, stdio: 'pipe' });

  const expected = fs.readFileSync(path.join(root, 'src', 'Generated', 'I18n.elm'), 'utf8');
  const actual = fs.readFileSync(temporaryElm, 'utf8').replace('module Generated.I18nCheck', 'module Generated.I18n');
  if (actual !== expected) {
    throw new Error('Generated Elm accessors are stale; run npm run i18n:generate');
  }

  for (const name of fs.readdirSync(temporaryAssets)) {
    const deployed = path.join(root, 'public', 'assets', 'i18n', name);
    if (!fs.existsSync(deployed)) throw new Error(`Missing translation asset ${name}`);
    if (!fs.readFileSync(deployed).equals(fs.readFileSync(path.join(temporaryAssets, name)))) {
      throw new Error(`Translation asset is stale: ${name}`);
    }
  }
  console.log('Translation catalogs and generated assets are current.');
} finally {
  fs.rmSync(temporaryElm, { force: true });
  fs.rmSync(temporaryAssets, { recursive: true, force: true });
}

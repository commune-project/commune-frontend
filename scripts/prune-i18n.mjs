import fs from 'node:fs';
import path from 'node:path';

const generated = fs.readFileSync('src/Generated/I18n.elm', 'utf8');
const current = new Set(generated.match(/messages\.[A-Za-z0-9-]+\.[0-9]+\.json/g) || []);
if (current.size !== 3) throw new Error(`Expected three generated catalogs, found ${current.size}`);

const assets = path.resolve('public/assets/i18n');
for (const name of fs.readdirSync(assets)) {
  if (name.endsWith('.json') && !current.has(name)) fs.rmSync(path.join(assets, name));
}

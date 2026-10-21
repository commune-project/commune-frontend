import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function stageRelease(distDirectory, outputDirectory, previousDirectory) {
  fs.mkdirSync(outputDirectory, { recursive: true });
  fs.cpSync(distDirectory, outputDirectory, { recursive: true });

  const previousCatalogs = previousDirectory && path.join(previousDirectory, 'assets', 'i18n');
  if (previousCatalogs && fs.existsSync(previousCatalogs)) {
    const destination = path.join(outputDirectory, 'assets', 'i18n');
    fs.mkdirSync(destination, { recursive: true });
    for (const name of fs.readdirSync(previousCatalogs)) {
      if (!name.endsWith('.json')) continue;
      const target = path.join(destination, name);
      if (!fs.existsSync(target)) fs.copyFileSync(path.join(previousCatalogs, name), target);
    }
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [dist = 'dist', output = 'release', previous] = process.argv.slice(2);
  stageRelease(path.resolve(dist), path.resolve(output), previous ? path.resolve(previous) : undefined);
  console.log(`Staged ${dist} at ${output}${previous ? ` retaining hashed catalogs from ${previous}` : ''}.`);
}

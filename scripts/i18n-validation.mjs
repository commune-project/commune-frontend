const messagePattern = /^([A-Za-z0-9-]+)\s*=\s*(.*)$/;
const placeholderPattern = /\{\s*\$([A-Za-z0-9_-]+)/g;

export function parseCatalog(fileName, source) {
  const localeMatch = /^messages\.(.+)\.ftl$/.exec(fileName);
  if (!localeMatch) return { error: `${fileName}: expected messages.<locale>.ftl` };

  const messages = new Map();
  let current = null;
  for (const line of source.split(/\r?\n/)) {
    const keyMatch = messagePattern.exec(line);
    if (keyMatch) {
      current = keyMatch[1];
      messages.set(current, keyMatch[2]);
    } else if (current && /^\s+/.test(line)) {
      messages.set(current, `${messages.get(current)}\n${line}`);
    } else if (line.trim() === '' || line.startsWith('#')) {
      current = null;
    }
  }

  const values = {};
  for (const [key, message] of messages) {
    values[key] = { message, placeholders: [...message.matchAll(placeholderPattern)].map(match => match[1]).sort() };
  }
  return { locale: localeMatch[1], messages: values };
}

export function validateCatalogs(files) {
  const errors = [];
  const catalogs = [];
  for (const [fileName, source] of Object.entries(files)) {
    const parsed = parseCatalog(fileName, source);
    if (parsed.error) {
      errors.push(parsed.error);
    } else {
      catalogs.push({ fileName, ...parsed });
      if (parsed.messages['catalog-id']?.message.trim() !== parsed.locale) {
        errors.push(`${fileName}: catalog-id must equal ${parsed.locale}`);
      }
    }
  }
  if (catalogs.length === 0) return ['No message catalogs found'];

  const reference = catalogs[0];
  for (const catalog of catalogs.slice(1)) {
    for (const key of Object.keys(reference.messages)) {
      if (!catalog.messages[key]) errors.push(`${catalog.locale}: missing message ${key}`);
    }
    for (const key of Object.keys(catalog.messages)) {
      if (!reference.messages[key]) errors.push(`${catalog.locale}: unexpected message ${key}`);
      const expected = reference.messages[key];
      const actual = catalog.messages[key];
      if (expected && actual && expected.placeholders.join(',') !== actual.placeholders.join(',')) {
        errors.push(`${catalog.locale}: placeholder mismatch for ${key}`);
      }
    }
  }
  return errors;
}

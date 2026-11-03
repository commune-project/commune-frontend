import { parse } from 'lossless-json';

// Keep protocol revisions and notification identities exact before Elm decodes them.
export function normalizeResponse(body) {
  if (!body) return null;
  const value = parse(body, undefined, {
    parseNumber: token => {
      const number = Number(token);
      return Number.isSafeInteger(number) ? number : token;
    }
  });
  function visit(item) {
    if (Array.isArray(item)) return item.map(visit);
    if (item && typeof item === 'object') {
      return Object.fromEntries(Object.entries(item).map(([key, child]) => [key,
        key === 'version' || key === 'id' && typeof child === 'number' ? String(child) : visit(child)]));
    }
    return item;
  }
  return visit(value);
}

export const formattingLocale = locale => ({
  'zh-cmn-Hans-CN': 'zh-Hans-CN', 'zh-cmn-Hant-TW': 'zh-Hant-TW'
}[locale] || 'en-US');

export function pluralCategory(locale, value) {
  try { return new Intl.PluralRules(formattingLocale(locale)).select(value); }
  catch { return 'other'; }
}

export function formatTime(locale, source) {
  const date = new Date(source);
  if (!Number.isFinite(date.getTime())) return source;
  try {
    const tag = formattingLocale(locale);
    return new Intl.DateTimeFormat(tag, { dateStyle: 'medium', timeStyle: 'short' }).format(date);
  } catch { return source; }
}

export function readPreference(storage) {
  try { return storage.getItem('commune.locale'); } catch { return null; }
}

export function savePreference(storage, locale) {
  try { storage.setItem('commune.locale', locale); } catch { /* Use the in-memory preference. */ }
}

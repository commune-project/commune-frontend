import './style.css';
import { normalizeResponse, formatTime, formattingLocale, pluralCategory, readPreference, savePreference } from './bridge.js';

let storage;
try { storage = window.localStorage; } catch { storage = null; }
const verificationToken = location.pathname === '/verify-email' ? new URLSearchParams(location.hash.slice(1)).get('token') || '' : '';
if (verificationToken) history.replaceState(null, '', location.pathname + location.search);
const csrf = () => document.cookie.split(';').map(v => v.trim()).find(v => v.startsWith('__Host-commune_csrf='))?.split('=').slice(1).join('=') || '';
const formatTimes = () => {
  const locale = document.documentElement.lang || 'en-US';
  for (const element of document.querySelectorAll('time[data-commune-time]')) {
    if (element.dataset.communeFormattedLocale === locale) continue;
    const result = formatTime(locale, element.getAttribute('datetime') || element.textContent || '');
    element.textContent = result.absolute + ' · ' + result.relative;
    element.dataset.communeFormattedLocale = locale;
  }
};
const app = window.Elm.Main.init({ node: document.getElementById('app'), flags: {
  languages: navigator.languages || ['en-US'], savedLocale: readPreference(storage), csrf: csrf(), verificationToken
} });

let composition = false;
let compositionEndedAt = 0;
document.addEventListener('compositionstart', () => { composition = true; app.ports.incoming.send({ kind: 'composition', active: true }); });
document.addEventListener('compositionend', () => { composition = false; compositionEndedAt = performance.now(); app.ports.incoming.send({ kind: 'composition', active: false }); });
document.addEventListener('keydown', event => {
  if (event.key === 'Enter' && (event.isComposing || composition || event.keyCode === 229 || performance.now() - compositionEndedAt < 80)) {
    event.preventDefault();
  }
}, true);
app.ports.outgoing.subscribe(message => {
  if (!message || typeof message.action !== 'string') return;
  switch (message.action) {
    case 'decode': {
      try { app.ports.incoming.send({ kind: 'decoded', id: message.id, status: message.status, value: normalizeResponse(message.body) }); }
      catch { app.ports.incoming.send({ kind: 'decoded', id: message.id, status: 0, value: null }); }
      break;
    }
    case 'locale':
      document.documentElement.lang = message.locale;
      document.documentElement.dir = import.meta.env.DEV && new URLSearchParams(location.search).has('test-rtl') ? 'rtl' : 'ltr';
      savePreference(storage, message.locale);
      formatTimes();
      break;
    case 'csrf': app.ports.incoming.send({ kind: 'csrf', value: csrf() }); break;
    case 'format': {
      const times = message.times.map(source => ({ source, ...formatTime(message.locale, source) }));
      let numbers = [];
      try { numbers = message.numbers.map(value => ({ source: value, text: new Intl.NumberFormat(formattingLocale(message.locale)).format(value) })); } catch { numbers = message.numbers.map(value => ({ source: value, text: String(value) })); }
      const plurals = (Array.isArray(message.plurals) ? message.plurals : [])
        .filter(Number.isFinite)
        .map(value => ({ source: value, category: pluralCategory(message.locale, value) }));
      app.ports.incoming.send({ kind: 'formatted', locale: message.locale, times, numbers, plurals });
      break;
    }
    case 'focus': requestAnimationFrame(() => document.getElementById(message.id)?.focus()); break;
    case 'dialog-open': requestAnimationFrame(() => {
      const dialog = document.getElementById(message.id);
      if (dialog && !dialog.open && typeof dialog.showModal === 'function') dialog.showModal();
    }); break;
    case 'dialog-close': {
      const dialog = document.getElementById(message.id);
      if (dialog?.open) dialog.close();
      break;
    }
  }
});
new MutationObserver(formatTimes).observe(document.getElementById('app'), { childList: true, subtree: true });
formatTimes();

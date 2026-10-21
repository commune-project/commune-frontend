# Accessibility and testing evidence

The frontend targets applicable WCAG 2.2 Level A and AA criteria. Automated checks ran on 2026-10-21 against Chromium supplied by `/usr/bin/chromium`; this is evidence for the tested environment, not a claim of complete conformance.

## Automated results

- 20 Elm unit tests passed: DTO decoding, route parsing and pagination, safe URL handling, locale alias/script negotiation, exact identifiers, Intl mappings, request generations, stale response rejection, switch notices, and fallback retry state.
- 11 JavaScript tests passed: large-number preservation, locale mappings, plural categories, date/time formatting, invalid date fallback, storage denial, catalog parity, missing keys, placeholder mismatch, current hashed assets, no remote translation URLs, and release staging that retains prior hashed catalogs.
- 36 mock-browser Playwright tests passed: discovery, auth and verification, invalid credentials, source-backed edit conflict, community creation, Chinese search, likes, deletion confirmation, uploads, profile/avatar, notifications, permission-aware management and endpoints, rich-content sanitization, API error mapping, focus, dialogs, localization, RTL, reduced motion, forced colors, and enlarged text/text-spacing layouts.
- 35 tests passed against the production preview; the only excluded test is the development-only RTL query injection.
- One separate real-backend Playwright test passed against HTTPS, PostgreSQL, CSRF, multipart media, the background notification worker, and a second account.
- `openspec validate ... --strict` passed for the active frontend change and archived localization main spec.

Run them with an explicit Elm cache:

```sh
ELM_HOME=/tmp/commune-elm-home npm test
ELM_HOME=/tmp/commune-elm-home npm run dev -- --port 4173
npm run test:browser
```

The Playwright suite expects the development server to be running. It exercises every implemented route, form, confirmation, responsive layout, mixed-direction content, and failure state.

The real-backend test is enabled only when its isolated services and credentials are supplied:

```sh
COMMUNE_REAL_BACKEND=1 \
COMMUNE_TEST_URL=https://localhost:8443 \
COMMUNE_REAL_ADMIN_PASSWORD='...' \
COMMUNE_REAL_USER_PASSWORD='...' \
  ./node_modules/.bin/playwright test tests-browser/real-backend.spec.js
```

Do not commit real credentials. The local test proxy is documented by `tests-server/https-proxy.mjs` and exists only for acceptance.

## Manual checks

The following checks require interactive environments unavailable to this automated run and remain explicitly unverified:

- NVDA with Firefox on Windows across all three locales
- VoiceOver with Safari on macOS and iOS across all three locales
- Real keyboard/IME composition with Chinese candidate selection on Linux, macOS, and Windows
- Native OS forced-colors review and browser text-only zoom at 200%
- Human linguistic review beyond the complete translation catalogs and automated parity checks

The automated composition guard, mixed Arabic/Indic/Thai/CJK fixture, joined emoji, RTL development layout, reduced-motion emulation, and forced-colors emulation reduce regression risk but do not replace these checks. Record browser and assistive-technology versions when completing them.

## Design safeguards

The shell provides a skip link, semantic landmarks, one page `h1`, persistent labels, visible focus, 48 CSS-pixel control targets, localized live status, a semantic progress bar, native selects and textareas, and logical-direction CSS. Dynamic language switching keeps focus on the language selector. Initial loading and fallback announce status without requiring a page reload.

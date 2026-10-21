# Dynamic localization

Travelm Agency compiles Fluent catalogs into typed Elm accessors and content-addressed JSON. The browser loads only the selected catalog from the Commune origin. There is no translation SaaS, remote CDN, API key, or provider request at runtime.

## Locale identities

| Public catalog identity | Browser Intl formatting | Native label |
| --- | --- | --- |
| `en-US` | `en-US` | English |
| `zh-cmn-Hans-CN` | `zh-Hans-CN` | 简体中文 |
| `zh-cmn-Hant-TW` | `zh-Hant-TW` | 繁體中文 |

The first column is preserved in storage, document metadata, diagnostics, and tests. Intl uses the shorter script-region form because the full extlang form can be rejected by browser implementations. Translation source files follow `messages.<public-locale>.ftl`.

Selection order is an explicit saved choice, supported browser languages in preference order, then English. An explicit `Hant` script outranks a conflicting region. Bare `zh` and `cmn` select Simplified Chinese. A denied localStorage read or write leaves selection in memory.

## Catalog lifecycle

Run `npm run i18n:generate` after changing `.ftl` files. The command:

1. Generates `src/Generated/I18n.elm` and hashed JSON under `public/assets/i18n/`.
2. Removes old hashes from the working tree so local and production builds contain only the current release.
3. Leaves compatibility retention to deployment, where prior hashed catalogs are copied into a new release directory for the supported client-cache window.

`npm run i18n:check` validates equal message identities and placeholder signatures across all three catalogs, regenerates into temporary paths, and checks that committed Elm accessors and current hashed assets match. Missing keys, mismatched placeholders, stale accessors, or stale current assets fail the check.

## Runtime behavior

The first page load requests the negotiated catalog. If that request fails, it requests English and then shows normal content with a localized fallback notice. If English also fails, an exceptional recovery shell keeps the language chooser and retry action available.

A later language choice increments a request generation. The current interface remains usable and the selector stays enabled while the catalog loads. Only the latest generation may replace the active catalog. A failed, malformed, wrong-identity, non-JSON, or superseded response does not change the active language. Draft text, route state, and logical focus remain in the existing Elm model.

Each JSON catalog carries an internal catalog identity. The client checks both the embedded identity and the generated `Language` before applying a response. This prevents a valid catalog for the wrong language from silently replacing the interface.

## Adding messages and languages

Add the same key and placeholder names to every existing catalog. Use complete messages for terminology and plural forms; avoid concatenating translated fragments. Count labels use browser `Intl.PluralRules` to select `one` or `other`, and displayed numbers use `Intl.NumberFormat`.

When adding a locale, add the Fluent file, extend `Locale` negotiation and labels, update the public-to-Intl mapping, regenerate accessors, and extend browser parity and accessibility tests. A new right-to-left interface locale also needs a production review of mirrored navigation and icons; the current `?test-rtl` option exists only to exercise shared component layout during development.

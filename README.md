# Commune frontend

Elm frontend for Commune's site-scoped forum APIs. It provides public discovery, account sessions and verification, discussions and nested replies, source-backed editing, media, profiles, search, notifications, community creation, and scoped moderation through a responsive Material Design interface. Localization resources are tracked by the archived `adopt-travelm-dynamic-localization` change and the active frontend change.

The interface targets WCAG 2.2 A/AA and ships complete `en-US`, `zh-cmn-Hans-CN`, and `zh-cmn-Hant-TW` catalogs. The backend contract is unchanged; the browser and backend share one HTTPS origin.

## Requirements

- Node.js 20 or newer and npm
- A writable `ELM_HOME`; this environment uses `/tmp/commune-elm-home` because the default home cache is read-only
- Optional `COMMUNE_BACKEND` URL for the Vite development proxy

## Commands

Install pinned dependencies and generate the current translation resources:

```sh
npm ci
npm run i18n:generate
```

Compile, test, or build with an explicit Elm cache:

```sh
ELM_HOME=/tmp/commune-elm-home npm run compile
ELM_HOME=/tmp/commune-elm-home npm test
ELM_HOME=/tmp/commune-elm-home npm run build
npm run i18n:check
```

Run browser tests against an already running development server:

```sh
ELM_HOME=/tmp/commune-elm-home npm run dev -- --port 4173
npm run test:browser
```

The `ELM_HOME` setting is intentionally supplied on each command. It is not embedded in `package.json`.

## Project layout

- `translations/`: translator-owned Fluent catalogs
- `src/Generated/I18n.elm`: generated typed message accessors
- `public/assets/i18n/`: current content-addressed catalog JSON
- `src/Locale.elm`: exact public locale identifiers and alias negotiation
- `src/Localization.elm`: request-generation state machine
- `src/Main.elm`: localized application shell and accessible interactions
- `tests/`, `tests-js/`, `tests-browser/`: focused unit and browser verification
- `deploy/nginx.conf`: same-origin frontend, API, federation, and media routing sample
- `tests-server/https-proxy.mjs`: local-only HTTPS proxy used for real-backend acceptance

See `docs/architecture.md`, `docs/localization.md`, `docs/deployment.md`, and `docs/accessibility-and-testing.md` for implementation and operational details. Authored project documentation and source comments use English; translation values and multilingual fixtures retain their own languages.

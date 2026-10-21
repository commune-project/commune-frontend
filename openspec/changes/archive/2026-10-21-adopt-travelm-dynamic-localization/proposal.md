## Why

The initial frontend scaffold embeds three languages in a handwritten Elm module, making translation maintenance and richer messages cumbersome. The approved Travelm Agency dynamic approach separates translator-owned Fluent files from generated, type-safe Elm accessors and loads only the selected language from Commune's own static hosting.

## What Changes

- Adopt Travelm Agency with Fluent `.ftl` catalogs and dynamic generated JSON bundles for `en-US`, `zh-cmn-Hans-CN`, and `zh-cmn-Hant-TW`.
- Fetch the selected catalog at startup and on demand; retain the current working interface until a requested language is ready, preserve drafts, reject stale switch responses, and expose accessible retry/recovery states.
- Validate complete catalogs, placeholder signatures, plurals, and localized date/number behavior during the build and tests.
- Serve content-addressed translation assets from the same origin, deploy them with their generated accessors, and retain assets needed by older open clients.
- Keep exact public locale identifiers and explicit browser-formatting mappings; retain existing RTL, complex-script, accessibility, and English-documentation requirements.
- Reconcile the original frontend change's localization design and task wording with this decision. This proposal does not implement code or add backend endpoints.

## Capabilities

### New Capabilities

- `dynamic-localization-resources`: Complete, type-safe translation resources with on-demand same-origin loading, atomic switching, recovery, and release-compatible caching.

### Modified Capabilities

None. There are no archived main specs yet. This capability supplements `localized-interface`, which is still defined in the active `build-accessible-localized-elm-frontend` change, without duplicating or weakening it.

## Impact

Implementation will affect the unfinished `src/I18n.elm` scaffold, locale state, bootstrap/Intl integration, build scripts and lockfile, Fluent resources, generated Elm/JSON artifacts, deployment routing, tests, and English documentation. Travelm Agency is a build-time dependency; the shipped site requires no translation SaaS, API key, third-party CDN, or remote formatting service. The existing frontend change remains the owner of complete forum workflows; this focused change owns their localization resource pipeline and lifecycle. Both sets of acceptance checks are required before the initial release.

## Context

See proposal.md for motivation. The existing localization plan in `build-accessible-localized-elm-frontend` requires complete three-locale catalogs, runtime selection, localized formatting, and accessible feedback. The current scaffold handwrites `I18n.elm` and formats through a JavaScript port. This change replaces that unfinished catalog design with generated dynamic resources while leaving the broader forum scope in the existing change.

## Goals / Non-Goals

**Goals:** Keep translator content separate from Elm code, catch catalog and parameter drift during generation and compilation, load only selected catalogs at runtime, and make switching recoverable and race-safe.

**Non-Goals:** Translation management SaaS, a custom translator portal, remote CDN hosting, automatic source translation, live locale updates without a page reload after deployment, plural-rule reimplementation, or implementation of the complete forum application in this planning change.

## Decisions

### 1. Use Fluent input and generated dynamic JSON

Add a pinned Travelm Agency development dependency and run its generator in a deterministic build step. Maintain three Fluent catalogs under a dedicated translation directory. Generate one Elm accessor module plus locale JSON bundles into a deployment directory. Use Travelm's dynamic mode (omit `--inline`), with generated functions taking the active `I18n` instance. The JSON is an application asset; no translation package is imported at runtime.

Travelm's cross-language key checking and generated parameter functions provide compile-time failures for catalog drift. Pin Node, npm lockfile, generator, and generated output expectations. CI SHALL regenerate and fail on unexplained diffs so generated source is reviewable.

### 2. Separate public locale identity from Travelm catalog keys

Keep the public identifiers `en-US`, `zh-cmn-Hans-CN`, and `zh-cmn-Hant-TW` in application state, persistence, document metadata, tests, and user-facing diagnostics. Use stable internal Travelm catalog keys if its generated constructor names cannot legally represent the full extlang-script-region tags; the adapter maps each public locale to exactly one internal bundle. Browser Intl formatting continues to map to `en-US`, `zh-Hans-CN`, and `zh-Hant-TW` through a tested function.

The adapter initializes one generated `I18n` instance first, then applies the loaded bundle. Catalog filenames and generated loader paths are fixed at build time and include a release or content identity. Do not derive asset paths from untrusted query parameters.

### 3. Model translation loading as a small explicit state machine

Model loaded catalogs separately from the requested target. Keep a monotonic switch generation and include it in the request callback. On switch:

1. Validate and normalize the public locale.
2. Increment the switch generation and mark the target as loading.
3. Keep the current catalog active and the page interactive.
4. On success, accept only the matching latest generation; atomically replace the catalog, active public locale, `lang`, `dir`, and formatting locale.
5. On failure, retain the current catalog, expose retry for the target, and announce the localized failure.

Persist an explicit choice only when it becomes active, except that a request to retry is session-local. Preserve the Elm page model and editor text across catalog replacement; do not remount the whole application or navigate.

### 4. Resolve initial loading with an English fallback

On first load, derive the requested public locale from the current negotiation rules. Attempt its catalog first. If that fails, attempt English. Render a minimal semantic boot status while no catalog is usable; its visible text must come from a tiny static boot-safe vocabulary or remain site-name plus non-text progress with no misleading translated content. After English loads, show normal content with a localized notice and target retry. If English also fails, render an exceptional accessibility-safe recovery shell containing native language names, retry, and a link/button to reload, using minimal English only.

Avoid caching error responses. Cache successful same-origin catalogs in the browser only according to deployment cache validity; the in-memory active catalog is the source of truth during a session. The JavaScript bridge may perform catalog requests for generated loaders and must validate response shape/version before passing it to Elm.

### 5. Publish immutable assets with compatibility retention

Generate catalog URLs containing a release hash, for example `/assets/i18n/messages.<locale>.<hash>.json`. Serve these with a long-lived immutable cache header. Catalog paths are fixed by the generated/accessor build, so no manifest request is required. Deploy matching JS and catalog assets together; retain prior hashed assets through the supported client-cache window. The static server's SPA fallback applies only to frontend routes and never to missing `/assets/i18n/...` or `/api/...` paths.

No service worker is introduced by this change. A 404, HTML content type, decode failure, unexpected catalog identity, or mismatched manifest/version is a failed load and must not be applied. Use the same origin and omit credentials from static catalog requests where the host permits; catalogs contain interface strings only.

### 6. Keep formatting and accessibility integrated with the catalog

Translate messages as complete Fluent entries, including plural selectors and accessible/live labels. Use generated functions for visible and assistive text. Date, number, and relative-time formatting stays in the narrow JavaScript Intl bridge, keyed by formatting locale and request generation so late callbacks cannot overwrite newer language state. If Intl fails, show a safe textual fallback without crashing the catalog switch.

After a successful switch, announce the language change once through a restrained live region, update document title and language metadata, and keep focus on the language control. Do not move focus to the page heading for an in-place language switch. Translation loading indicators and retries use semantic controls, meet target-size and contrast requirements, and respect reduced motion and forced colors.

### 7. Verification uses generated contracts and real browser races

Unit tests cover locale alias mapping, catalog-key mapping, switch-generation acceptance, malformed/failed responses, fallback order, Intl locale mapping, and draft preservation. A build check proves all three Fluent catalogs have matching message identities and compiles the regenerated Elm. Browser tests use delayed and intentionally failing same-origin asset routes to exercise startup fallback, rapid switching, announcement, retry, refresh, offline failure, nonexistent hashed assets, and all three locales with axe-core scans. Accessibility acceptance still requires manual keyboard, screen-reader, RTL, and IME checks.

## Risks / Trade-offs

- [Additional initial request delays usable content] → Load only the selected catalog, show semantic progress, and fall back to English on failure.
- [Generated accessors and catalog JSON can drift across deployments] → Build, hash, and deploy them as one unit; retain preceding assets and reject version mismatches.
- [Dynamic catalogs increase failure paths] → Keep the current catalog active, discard stale generations, and test malformed, 404, HTML fallback, and retry cases.
- [Travelm may not accept the public tag as an internal constructor] → Use a tested adapter between exact public locale IDs and stable internal catalog keys.
- [Fluent and generated HTML can interact with sanitization] → Keep user content in the existing sanitized rich renderer; translation HTML is trusted build output only and receives accessibility review.
- [Generated code increases repository diff noise] → Pin the generator, use deterministic output, and verify regeneration in CI.

## Migration Plan

Add the generator and catalogs without changing production behavior, generate the accessors and bundles, and verify all messages across locales. Replace the handwritten three-language accessor with an adapter and generated dynamic loader behind the existing localization state. Add startup fallback and switch recovery, then deploy matching frontend and immutable catalog assets in one release. Watch catalog 404/decode errors before removing the old accessor. Roll back by deploying the previous frontend release and retaining previous catalog hashes; catalog assets are additive and no backend or database migration is required.

## Open Questions

None that change the approach or acceptance contract. The concrete Travelm-generated constructor names and loader signature will be verified against the pinned generator during implementation; the public locale adapter isolates those details.

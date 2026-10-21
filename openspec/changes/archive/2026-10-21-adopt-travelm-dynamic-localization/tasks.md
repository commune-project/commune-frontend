## 1. Generator and catalog foundation

- [x] 1.1 Add a pinned Travelm Agency development dependency and deterministic generation scripts; verify a clean npm install, generator help/version output, and repeat generation produces no unexplained diff.
- [x] 1.2 Create `en-US`, `zh-cmn-Hans-CN`, and `zh-cmn-Hant-TW` Fluent catalogs with matching message identities and parameter declarations; verify intentionally removing or changing one placeholder causes catalog validation to fail.
- [x] 1.3 Generate the dynamic Elm accessor module and same-origin JSON bundles, excluding inline catalog generation; verify the production build references dynamic URLs and does not embed all three catalogs in the main bundle.
- [x] 1.4 Add a build/CI check that regenerates catalogs and fails on drift or catalog inconsistencies; verify the check passes unchanged and fails for a controlled catalog divergence.

## 2. Locale adapter and state model

- [x] 2.1 Implement an adapter between exact public locale identifiers, generated catalog languages, bundle paths, native labels, and browser Intl formatting locales; verify all three locales and `zh`/`cmn` aliases in unit tests.
- [x] 2.2 Replace the handwritten three-language lookup with generated message accessors while preserving active public-locale state and document metadata; verify compiling an obsolete or mistyped message reference fails.
- [x] 2.3 Implement loaded/current, requested target, loading, failed-target, fallback notice, and monotonic switch-generation state; verify unit tests reject stale, duplicate, and mismatched responses.
- [x] 2.4 Ensure a successful catalog replacement preserves page model, route, unsent editor content, logical focus, and scroll context; verify language changes in open forms do not reset text or values.

## 3. Dynamic loading and recovery

- [x] 3.1 Implement initial dynamic loading using saved/browser negotiation, selected-catalog-first behavior, English fallback, and all-catalogs-failed recovery; verify normal, fallback, and complete failure paths in browser tests.
- [x] 3.2 Implement on-demand switching that keeps the current interface usable until the new catalog is ready and updates locale metadata only after acceptance; verify delayed requests display stable current content and controls.
- [x] 3.3 Implement localized retry for failed switches and startup fallback without claiming success or partially applying messages; verify 404, malformed JSON, wrong catalog identity, and HTML fallback responses.
- [x] 3.4 Validate catalog responses at the client boundary and pass only the expected generated format to Elm; verify malformed values cannot execute code, corrupt state, or overwrite newer results.
- [x] 3.5 Announce successful switches, fallback substitutions, failures, and retries through restrained semantic live regions while retaining focus on the language control; verify keyboard and screen-reader feedback with browser tests where automatable.

## 4. Formatting and multilingual presentation

- [x] 4.1 Wire generated plural and parameterized messages for counts, errors, accessible names, and dynamic statuses; verify English, Simplified Chinese, and Traditional Chinese output plus Intl plural selection.
- [x] 4.2 Keep dates, relative times, and numbers in the browser Intl bridge with formatting-locale mappings and request generations; verify stale formatting callbacks cannot overwrite a newer locale and invalid input has a safe fallback.
- [x] 4.3 Verify mixed Arabic/Latin/CJK content, actor URI isolation, RTL test layout, complex scripts, and IME composition before and after language switching; record any unavailable manual checks explicitly.
- [x] 4.4 Run accessibility scans in all three locales during loading, fallback, and switching states; verify labels, live feedback, contrast, target sizes, reduced motion, forced colors, and focus behavior.

## 5. Asset delivery and deployment

- [x] 5.1 Configure generated dynamic catalog paths to include a release/content hash and serve them with immutable caching; verify the emitted accessor always requests a matching existing asset.
- [x] 5.2 Configure static hosting so missing translation assets return real not-found responses and `/assets/i18n/` plus `/api/` paths never receive the SPA HTML fallback; verify direct asset, missing asset, and application deep-link requests.
- [x] 5.3 Document matching frontend/accessor/catalog deployment, retained hashes for older clients, and rollback; verify a simulated previous-release asset remains loadable during the retention window.
- [x] 5.4 Confirm production has no translation SaaS, remote CDN, API-key, or provider request path; verify language loading and switching work with external network access unavailable and same-origin assets healthy.

## 6. Reconciliation and acceptance

- [x] 6.1 Update the active `build-accessible-localized-elm-frontend` design and tasks to reference generated dynamic catalogs and remove hand-maintained translation lookups; re-read both changes and verify they prescribe one coherent implementation.
- [x] 6.2 Add focused unit and browser coverage for fallback order, rapid switching, retry, malformed assets, cache identity, draft preservation, and every supported locale; verify these tests fail on a reverted switch-generation or fallback guard.
- [x] 6.3 Operate every currently available localized application workflow and state in all three languages, then document visible formatting, accessibility, and mixed-direction outcomes in an English evidence report; the broader forum workflows remain owned by the companion frontend change.
- [x] 6.4 Validate both OpenSpec changes strictly, audit authored documentation/comments for English, and verify no runtime provider dependency, incomplete catalog, stale asset reference, or implementation claim remains.

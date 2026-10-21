## 1. Foundation and contract baseline

- [ ] 1.1 Scaffold the Elm application, minimal Vite bootstrap, pinned dependencies, formatting, elm-test, and browser test commands; verify a clean install, production build, and initial test run.
- [ ] 1.2 Record current backend request/response fixtures and deployment prerequisites for every planned flow; verify them against handler behavior and stop/report if a required capability is missing.
- [ ] 1.3 Implement typed domain decoders and API error mapping including optional fields and all documented statuses; verify valid, malformed, forbidden, conflict, rate-limit, and unavailable fixtures.
- [ ] 1.4 Implement routes, URL builders, navigation state, request identities, and session-generation guards; verify direct links, query parameters, back/forward, and ignored stale responses.
- [ ] 1.5 Implement the documented browser bridge for preferences, CSRF, Intl, storage, focus, and composition where required; verify validated port payloads and denied-storage/unsupported-formatting fallbacks.

## 2. Localization foundations

- [ ] 2.1 Implement all three exact locale identifiers, alias negotiation, explicit-choice persistence, native language chooser labels, and document language/direction updates; verify ordered browser preferences, script precedence, bare Chinese, reload, and storage failure.
- [ ] 2.2 Establish typed message catalogs and parameter/completeness checks; verify missing entries fail checks and every component can obtain both visible and accessible strings.
- [ ] 2.3 Implement locale-specific count, plural, date, relative-time, and absolute-time formatting using safe Intl locale mappings; verify each locale, browser time zones, invalid dates, and stale formatting responses.
- [ ] 2.4 Establish logical CSS, text-direction isolation, script font fallbacks, and RTL/expanded-text fixtures; verify mixed Arabic/Latin/CJK, Devanagari, Thai, combining marks, joined emoji, and long identifiers.

## 3. Material and accessibility primitives

- [ ] 3.1 Implement Material 3 tokens, typography, icons, cards, navigation, and responsive shell; verify wide/medium/320-pixel views and measured text/non-text contrast.
- [ ] 3.2 Implement labeled inputs, buttons, errors, loading/empty/error states, pagination, and localized live feedback; verify semantic roles, keyboard operation, target sizes, and axe-core results.
- [ ] 3.3 Implement accessible dialogs/drawers and route focus/title behavior; verify focus containment, Escape, background inertness, restoration, skip navigation, and unobscured focus.
- [ ] 3.4 Implement the allowlisted sanitized-HTML renderer with safe links, code, images, attachment names, and direction support; verify server-produced rich fixtures, malicious URLs/markup, descriptions, and no-referrer behavior.
- [ ] 3.5 Verify primitives with forced colors, reduced motion, 200% text resize, 400% zoom/reflow, and text-spacing overrides; record outcomes and fix clipping or inaccessible controls.

## 4. Accounts and authentication

- [ ] 4.1 Implement login, session restoration, logout, current roles, same-origin CSRF mutations, and protected-state cleanup; verify a real backend session lifecycle, invalid CSRF, session expiry, cross-site denial, and stale response handling.
- [ ] 4.2 Implement registration and resend with generic acceptance, disabled-registration, and rate-limit outcomes; verify enabled/disabled backend contracts without claiming email delivery on API acceptance.
- [ ] 4.3 Implement fragment capture/history cleanup, password selection, verification confirmation, and subsequent login; verify a real mailbox flow plus invalid/expired tokens and absence of token persistence or logs.
- [ ] 4.4 Verify account forms with password-manager autocomplete, paste, field errors, keyboard navigation, and IME composition; confirm Enter during composition cannot submit prematurely.

## 5. Discovery and discussion reading

- [ ] 5.1 Implement latest discussions and community directory with stable offset navigation; verify anonymous/authenticated visibility, loading/empty/error states, final empty pages, and return context.
- [ ] 5.2 Implement community detail, policies, mode labels, and permission-controlled compose/management entries; verify local-only, public/private federated, remote replica, and manager-without-membership fixtures.
- [ ] 5.3 Implement discussion detail and lazy paginated nested replies with bounded indentation; verify direct navigation, counts, deleted/unavailable objects, keyboard expansion, and mixed-direction reading.
- [ ] 5.4 Implement like/undo with pending-action guards and metadata refresh; verify backend state survives reload and failures never display false success.

## 6. Writing and media

- [ ] 6.1 Implement topic/reply editors, Markdown selection, composition-safe controls, and in-memory error recovery; verify real creation/reply flows and unchanged unsent text after recoverable failures or locale changes.
- [ ] 6.2 Implement source-backed editing and author deletion with confirmation; verify raw source and attachment preservation, legacy format behavior, denied permissions, and 409 recovery without silent overwrite.
- [ ] 6.3 Implement native file upload, returned-reference insertion, attachment binding/removal, and accessible upload status; verify accepted files, upload rejection, binding failures, and private media access using the backend.
- [ ] 6.4 Verify rich discussion display and downloads against public remote, local private, and compatible remote-private references; confirm no anonymous fallback and that editor source is never injected into display HTML.

## 7. Profiles search and notifications

- [ ] 7.1 Implement public local profiles and own-profile editing/avatar upload; verify PATCH omission/removal semantics, ownership denial, public avatar messaging, and real save/reload behavior.
- [ ] 7.2 Implement post/community search with URL-backed kind/query/pagination; verify Chinese literal matching, special characters, whitespace rejection, stale results, and access-filtered responses.
- [ ] 7.3 Implement notification lists, unread count, single read, and snapshot-based read-all; verify later arrivals remain unread and revoked/private notifications are removed after refresh.

## 8. Community management

- [ ] 8.1 Implement community creation with fixed federation mode and valid policy combinations; verify real creation and localized invalid/forbidden outcomes.
- [ ] 8.2 Implement policy editing and paginated member/manager rosters with add/remove actions; verify current permissions, creator flags, revocation, and no assumption that management grants posting.
- [ ] 8.3 Implement documented post removal/restore, submission-state, hide/unhide, import, and context-backfill actions where appropriate; verify each supported request contract and restricted-action rejection without inventing a moderation queue.

## 9. Translation and cross-workflow acceptance

- [ ] 9.1 Complete and separately review en-US, zh-cmn-Hans-CN, and zh-cmn-Hant-TW terminology and messages across every route/status/accessibility label; verify catalog parity and an untranslated-string audit.
- [ ] 9.2 Run browser workflow tests and axe-core scans in all three locales, plus test-only RTL and expanded-text configurations; verify navigation, form preservation, rich content, responsive layout, dialogs, and mixed-direction identities.
- [ ] 9.3 Run seeded real-backend integration covering accounts, discovery, source-backed CRUD, media, search, profiles, notifications, and management; record dependencies/results and stop/report any required API gap.
- [ ] 9.4 Manually verify keyboard-only core workflows and NVDA/Firefox plus VoiceOver/Safari in each locale where available; deliver an English evidence report and explicitly leave unavailable combinations or failures pending.
- [ ] 9.5 Manually verify real Chinese IME composition and Arabic/Indic/Thai/emoji rendering/input, zoom, text spacing, forced colors, and reduced motion; record tested platforms and resolve applicable conformance failures.

## 10. Delivery documentation

- [ ] 10.1 Write English setup, architecture, localization, accessibility, testing, and contribution documentation; verify commands from a clean checkout and audit authored comments/documentation for the English convention.
- [ ] 10.2 Add documented same-origin HTTPS proxy and explicit SPA fallback deployment configuration with registration hints and backend/media prerequisites; verify frontend deep links and backend federation/media paths do not intercept one another.
- [ ] 10.3 Run the final build/test checks and staging smoke flows, document static-release rollback, and deliver the requirement-to-evidence report; verify no backend edits, fabricated production data, or unsupported conformance claims remain.

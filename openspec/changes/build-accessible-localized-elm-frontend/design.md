## Context

See proposal.md for motivation. This checkout has only OpenSpec scaffolding. Backend contracts were checked against `docs/api.md`, `docs/authentication.md`, `docs/forum-browser-api.md`, `docs/participation-api.md`, and the connected server routes on 2026-10-21. No live service acceptance is implied by this inspection. The six previously identified browser API gaps are now represented in routing and DTOs.

## Goals / Non-Goals

**Goals:** Make application state predictable in Elm, keep browser interoperability narrow, and make localization, semantic accessibility, and directionality common component responsibilities. Deliver all workflows in the capability specifications without changing backend semantics.

**Non-Goals:** Backend development, new federation protocols, remote discovery, subscriptions/bookmarks, password reset, relevance sorting, a new moderation queue, server-side rendering, offline private-data caching, automatic user-content translation, or production RTL translations. Capability gaps in a required flow stop work and are reported rather than worked around.

## Decisions

### 1. Elm owns application behavior

Use Elm `Browser.application`, URL parsers/builders, `elm/http`, and page-local Model/Msg/update/view modules. Organize shared modules under Api, Domain, I18n, Ui, and Page. Typed DTO decoders preserve optional fields and distinguish loading, empty, ready, and failed states. Request identities include route/resource and session generation so stale responses cannot restore private data after navigation or logout. Keep mutation status per action and prevent duplicate submission. No automatic write retries.

A small JavaScript bootstrap supplies browser preferences, document language/direction, cookie-to-CSRF transport, storage, Intl formatting, composition state where native form behavior needs bridging, and browser APIs unavailable in Elm. Use validated, correlated ports with documented payloads; no parallel application state or business logic in JavaScript. Prefer Elm-controlled semantic DOM over an external Material web-component runtime, whose focus and lifecycle would be harder to coordinate. Use a minimal Vite build with pinned dependencies and Elm compilation rather than a second frontend framework.

### 2. Existing API contracts define pages

| UI route | Existing API surface |
| --- | --- |
| `/` | GET `/api/v1/topics` |
| `/communities`, `/communities/:id` | Community discovery/detail/topics |
| `/posts/:id` | Post detail, replies, likes, author edits/deletion |
| `/communities/new`, `/communities/:id/new` | Community and topic creation |
| `/posts/:id/edit` | GET source, PATCH post |
| `/login`, `/register`, `/verify-email` | Login/session/logout, register/resend/confirm |
| `/search` | Search with explicit posts/communities kind |
| `/notifications` | List, unread count, read and cursor-based read-all |
| `/profiles/:username`, `/settings/profile` | Public and own profile, avatar media |
| `/communities/:id/manage` | Policy, rosters and documented moderation mutations |

Use query parameters for search and offset. Follow the backend's stable sort and default page size of 20. Without totals, offer previous/next or load-more, tolerate an empty following page, and never fabricate a last-page number. Nested replies load lazily per parent with bounded visual indentation and explicit parent context. Local-only and federated read/post semantics are displayed separately. Management uses current `permissions`; it never infers membership from roles. Remote replicas respect server-disabled mutations. Actor URIs remain identities; only known local profile routes become local profile links.

After like/undo or management changes, reload affected metadata. Preserve unsent text in page memory on recoverable failures; do not persist private drafts or passwords. Clear sensitive state on logout/session expiry. Handle status codes with translated messages and use safe server error codes as diagnostics rather than assuming raw error prose is localized. Expose conflict recovery without overwriting silently. If a required endpoint or field proves insufficient, stop implementation and report evidence.

### 3. Same-origin deployment and narrow security boundaries

Serve assets and API behind the same HTTPS authority; proxy `/api/` to the backend and preserve federation/user/media/health backend routes rather than applying SPA fallback to them. Provide fallback only for frontend routes. Sessions stay in HttpOnly cookies. Read only the named CSRF cookie when issuing a mutation; never place cookies/tokens in localStorage. Login/registration Origin is browser-generated. Do not attempt to forge Origin or configure cross-origin cookie workarounds.

Capture verification fragments in memory, replace the history entry immediately, and avoid analytics/token logs. Static deploy configuration supplies only non-secret feature hints such as registration availability; the backend remains authoritative for rejection. This avoids requiring an unavailable public site-settings endpoint. Do not add a password-reset link without a supporting API.

### 4. Material Design through semantic components

Use CSS custom properties for Material 3 roles, spacing, shape, elevation, typography, focus, and interaction states. Default to a light theme with a restrained indigo primary and neutral surfaces, validating all combinations rather than relying on nominal palette values. Dark theme is outside initial scope; forced colors and reduced motion are supported. Use local SVG icons and system/script-aware font stacks without depending on remote icon fonts.

Wide view: navigation on inline-start, centered bounded discussion list, community context on inline-end. Medium view collapses context below content; compact view uses a modal navigation drawer, full-width cards, and an accessible compose action. Breakpoints follow content fit, initially around 600 and 1200 CSS pixels, and are verified with expanded strings and zoom. Discussion cards expose semantic headings, author/time, excerpt, and separate interaction controls; avoid nested links/buttons. Use explicit pagination rather than mandatory infinite scrolling.

### 5. Catalog identity is separate from browser formatting

Use a closed Elm Locale type and typed complete-message functions for all three catalogs. Preserve requested preference identifiers `en-US`, `zh-cmn-Hans-CN`, and `zh-cmn-Hant-TW` in application settings and document language. Map browser Intl formatting to interoperable `en-US`, `zh-Hans-CN`, and `zh-Hant-TW`; do not pass extlang identifiers directly to Intl, which can reject them. Normalize aliases explicitly, considering script before region; `zh`/`cmn` default to Simplified. Resolve a saved explicit choice first, then ordered navigator languages, then English. Storage failures use in-memory selection.

Use English, 简体中文, and 繁體中文 as native chooser labels. Every catalog includes visual and assistive strings with identical typed parameters. Generate or check completeness during builds; missing production translations fail verification. Use Intl plural categories and full message templates, never English word order concatenation. Formatting requests are keyed by locale and input to discard stale results; fall back safely if Intl is unavailable. Dates retain UTC API values, format in the browser time zone, and expose absolute values with semantic time markup. Locale switching does not navigate or recreate form models.

### 6. Direction, shaping, and composition are independent concerns

All production locales have LTR interface direction. Shared components consume locale direction metadata and use logical CSS properties, text-align start, and inline/block dimensions. A test-only RTL pseudo-locale exercises mirrored navigation, dialogs, rosters, and editors without advertising a fourth supported language. Mirror only icons with directional meaning. Render user text containers with `dir=auto`, and isolate actor handles/URIs with `bdi` or an appropriate explicitly directed element. Rich content inherits its own direction without reversing code or attachments.

Use native inputs/textareas and submission buttons. Track composition events when intercepting Enter or shortcuts, and never submit while composition is active. Avoid transforming input strings or naive code-unit slicing; use CSS line clamps for visual excerpts and grapheme segmentation if textual truncation is unavoidable. Support Arabic shaping, Indic combining sequences, Thai wrapping, and joined emoji through font fallback and natural line metrics. Avoid forced letter-spacing, fixed text heights, and break-all on prose; wrap long identifiers separately. No content-language inference is claimed when the backend provides none.

### 7. Accessibility belongs in shared behavior and acceptance

Target applicable WCAG 2.2 A/AA across every route and locale. Native semantics precede ARIA. Shared primitives own labels/descriptions, field errors, busy states, toggle/expanded states, focus rings, and localized live feedback. Use skip navigation, landmarks, a single page h1, and a predictable heading outline. On navigation update title and focus h1 after rendering; retain focus on pagination and expansion triggers. Modal dialogs/drawers use tested focus containment, background inertness, Escape handling, and restoration. Destructive operations require a named confirmation. Do not interrupt assistive reading with periodic count announcements.

Keep controls near 48 CSS pixels and verify WCAG target-size exceptions explicitly where relevant. Validate ordinary text at 4.5:1, large text and essential non-text indicators at 3:1. Test 200% text resize, 400% zoom/320-pixel reflow, prescribed text-spacing overrides, forced colors, reduced motion, and sticky-header focus visibility. Respect password managers, paste, autocomplete, and native file selection.

Parse server-sanitized `body_html` into an allowlisted Elm HTML tree rather than inserting arbitrary innerHTML. Preserve allowed semantic formatting, code, safe URLs, image descriptions, direction, and no-referrer remote-image behavior. Validate renderer parity using server-produced fixtures; unexpected markup must not execute and must not become editing source. Use plain display fallback only as an explicitly diagnosed rendering error, not silent feature substitution. No live Markdown preview is promised because there is no preview endpoint; preview can be a later capability.

### 8. Verification combines contracts and human checks

Use elm-test for decoders, URL handling, locale negotiation/aliases, messages, permissions-driven presentation, and stale-response behavior. Use Playwright with axe-core for real-browser workflows, focus, viewport changes, localization, and RTL fixtures. Contract fixtures exercise error paths, but acceptance also uses a seeded real backend for session/CSRF, CRUD, source editing, media, profiles, notifications, search, and rosters. Registration acceptance needs a test mailbox and real enabled workers. IME and complex-script input need manual checks in addition to synthetic event tests.

Manually verify NVDA with Firefox and VoiceOver with Safari where available, covering core workflows in each locale. Record unavailable combinations as unverified rather than claiming conformance. Keep an English evidence report mapping requirements to automated/manual outcomes. No applicable A/AA failure is accepted as complete; backend service or platform limitations are documented and reported.

## Risks / Trade-offs

- [Browser Intl rejects extended Chinese identifiers] → Keep exact catalog IDs and a tested formatting-locale mapping.
- [A custom component or rich renderer loses semantics] → Minimize custom widgets, validate against server fixtures, and include manual assistive checks.
- [Live contract differs from docs] → Verify against actual handler responses before expanding each flow; stop on required backend gaps.
- [Registration/mail/media depend on deployment configuration] → Document prerequisites and test enabled and disabled states without simulating production success.
- [Large translations and script font differences change geometry] → Exercise expanded pseudo-text, CJK, RTL, zoom, and complex-script fixtures at component and page levels.
- [Offset pages move during concurrent writes] → Explain refresh behavior, preserve route context, and avoid claiming stable totals.
- [Assistive technology is unavailable in the execution environment] → Automate what can be verified and explicitly leave manual acceptance pending.

## Migration Plan

There is no existing frontend data migration. Implement the foundation and contract checks first, then components and complete workflows, then translations and acceptance. Build immutable assets; configure same-origin HTTPS routing, explicit frontend fallback routes, registration hints, and security headers compatible with authorized media. Validate deploy configuration in staging against the selected site, mail sink, and media store. Roll back by restoring the preceding static asset release; do not change backend schema or delete authoritative media. Document build, local proxy, deployment, localization, accessibility testing, and rollback in English.

## References

- Backend contracts: `commune-backend/docs/forum-browser-api.md` and `commune-backend/docs/participation-api.md` in the sibling MyGO projects checkout.
- WCAG 2.2: https://www.w3.org/TR/WCAG22/
- Language tags and script subtags: https://www.w3.org/International/articles/language-tags/
- BCP 47 extlang examples: https://www.rfc-editor.org/rfc/rfc5646

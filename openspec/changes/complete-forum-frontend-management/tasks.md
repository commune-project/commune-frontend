## 1. Domain And Route Foundation

- [ ] 1.1 Extend `Domain.Identity`, post, community, and notification decoders with the documented fields and safe additive defaults; verify with focused `DomainTest.elm` decoding fixtures.
- [ ] 1.2 Add domain decoders for vote settings, reports, moderation log rows, account blocks, follow requests, and account content source selection; verify each decoder with representative and omitted-field fixtures.
- [ ] 1.3 Add bookmarkable account collection, personal block, password reset/change, and site administration route constructors and parsers; verify direct parsing and `Route.path` round trips in `RouteTest.elm`.
- [ ] 1.4 Add feature state and message slots for account collections, personal blocks, reports, and site administration to application composition; verify the application compiles without feature dependency cycles.

## 2. Post Interactions And Threads

- [ ] 2.1 Extend shared post-card configuration and rendering for upvote, downvote, save, personal hide, report, and existing edit/delete/reply actions; verify action names, selected states, and 320-pixel layout in component-focused browser tests.
- [ ] 2.2 Implement vote mutations with score values `1`, `-1`, and `0`, including clear-vote behavior when a direction is disabled; verify request bodies and refreshed `voted_by_me`, `upvotes`, `downvotes`, and `score` in mock-browser tests.
- [ ] 2.3 Implement save, mark-read, personal-hide, and personal-unhide mutations with per-target busy keys; verify duplicate submissions are blocked and successful mutations refresh authoritative post state.
- [ ] 2.4 Expand `App.Interaction` to patch authoritative post metadata across post detail, latest, community, search, and account collections; verify one refreshed post updates every visible representation.
- [ ] 2.5 Replace per-parent nested reply fetches with recursive `children`, `depth`, and `child_count` decoding and rendering; verify a multi-level tree renders without additional nested requests.
- [ ] 2.6 Add route-backed reply sort and maximum-depth controls using documented values; verify URL changes issue the expected root reply request and preserve sibling order.

## 3. Reporting And Account Features

- [ ] 3.1 Add a shared accessible report dialog for post, community, and person targets with reason validation and optional community scope; verify validation, CSRF submission, success, and failure focus behavior.
- [ ] 3.2 Add saved, read, hidden, and liked account collection routes and paginated views using standard post cards; verify route-specific endpoint selection and empty, loading, error, and exhausted states.
- [ ] 3.3 Add direct collection controls to unsave and unhide posts and refresh the current collection after membership or visibility changes; verify unavailable posts disappear from the refreshed page.
- [ ] 3.4 Add the personal blocks list and add/remove form for person, community, and instance kinds; verify kind-specific validation, localized server errors, and list refresh after mutation.
- [ ] 3.5 Add generic password reset request and fragment-token confirmation flows; verify the token is captured, removed from history, never persisted, and successful confirmation leads to login.
- [ ] 3.6 Add the authenticated password-change form under settings; verify current/new password payloads, successful field clearing, failure preservation, and current-session retention.

## 4. Community Management

- [ ] 4.1 Extend community decoding and presentation with follow policy, follower count, follow state, and follow permission; verify restricted counts are not inferred and all follow states render distinctly.
- [ ] 4.2 Add follow and unfollow actions to community detail; verify pending, accepted, rejected, undone, disabled-policy, and unfollow-after-disable behavior against mock responses.
- [ ] 4.3 Add follow-policy editing to community management and include it in the existing policy request; verify valid combinations and normalization remain correct.
- [ ] 4.4 Add paginated pending follow requests with accept and reject decisions using path-escaped Actor URIs; verify approval refreshes the queue and member roster.
- [ ] 4.5 Add community-scoped report review and moderation-log views to community management; verify the `community_id` filter is sent and no site-wide controls appear for community-only authority.
- [ ] 4.6 Add community-ban create and remove forms with Actor URI, reason, and optional RFC 3339 expiry; verify validation, successful refresh, and no active-ban inventory claim.

## 5. Current-Site Administration

- [ ] 5.1 Create the `Feature.SiteAdmin` State, Update, and View modules and gate all protected loads by authenticated site/deployment administrator roles; verify anonymous and ordinary-account routes issue no management reads.
- [ ] 5.2 Add the `/admin` overview that identifies the workspace as current-site scoped and links only to implemented surfaces; verify no deployment directory, cross-site aggregate, or site-switching control appears.
- [ ] 5.3 Implement `/admin/settings` vote-settings read and partial update with returned full settings; verify upvote-only and downvote-only updates and failure-state preservation.
- [ ] 5.4 Implement `/admin/reports` with state and community filters, pagination, inline details, and resolve/reject actions with optional notes; verify conflict handling refreshes the queue and moderation log.
- [ ] 5.5 Implement `/admin/modlog` with pagination and optional community filtering in newest-first backend order; verify rows remain read-only and absent community IDs are not inferred.
- [ ] 5.6 Implement `/admin/bans` site-ban create and remove forms; verify CSRF, expiry validation, not-found unban feedback, and moderation-log refresh after success.
- [ ] 5.7 Add site and community management cross-links without bypassing role or permission checks; verify links remain hidden or forbidden when authority is absent.

## 6. Navigation Localization And Accessibility

- [ ] 6.1 Add role-gated current-site management and authenticated My content/Blocks destinations to the drawer in the specified order; verify authenticated, administrator, ordinary-account, and anonymous drawer scenarios.
- [ ] 6.2 Add all new user-facing strings to `en-US`, `zh-cmn-Hans-CN`, and `zh-cmn-Hant-TW` catalogs and regenerate accessors; verify `npm run i18n:check` and generated-catalog parity.
- [ ] 6.3 Add responsive and forced-colors-safe styles for management lists, filters, forms, post actions, dialogs, and account collections; verify 320-pixel, 200% text, text-spacing, and no-overlap browser checks.
- [ ] 6.4 Add confirmation and focus behavior for report resolution, bans, block removal, and destructive management actions; verify Escape cancellation and trigger-focus restoration.
- [ ] 6.5 Update `docs/architecture.md` and `docs/backend-integration.md` with new feature ownership, routes, request groups, and the deferred deployment-management boundary; verify documentation matches implemented routes.

## 7. Verification

- [ ] 7.1 Add or update Elm unit tests for new DTOs, routes, reply trees, source selection, policy normalization, and role-gated state transitions; verify `ELM_HOME=/tmp/commune-elm-home npm test`.
- [ ] 7.2 Extend Playwright mock coverage for voting, follows, saved/read/hidden/liked lists, blocks, password flows, reports, community administration, and site administration; verify `npm run test:browser`.
- [ ] 7.3 Run axe scans over every new route in all required states; verify zero WCAG 2.2 A/AA automated violations at desktop and compact widths.
- [ ] 7.4 Run formatting, translation, compilation, and production build checks with `ELM_HOME=/tmp/commune-elm-home npm run format:check`, `npm run i18n:check`, `npm run compile`, and `npm run build`.
- [ ] 7.5 Attempt real-backend acceptance for the new flows against PostgreSQL and HTTPS; record unavailable infrastructure separately without claiming unexecuted checks passed.

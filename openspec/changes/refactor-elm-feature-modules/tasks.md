## 1. Migration Baseline

- [ ] 1.1 Document route entry/reset, draft retention, protected-state cleanup, and SessionLoaded/Loaded/ActionDone generation rules and exceptions; deliver a migration checklist comparable to the original implementation.
- [ ] 1.2 Run compile, test, and existing browser tests with `ELM_HOME=/tmp/commune-elm-home`; record passing checks and existing infrastructure/test failures as the pre-refactor baseline.

## 2. Shared Presentation and Browser Boundary

- [ ] 2.1 Extract Ui.Feedback, Ui.Pagination, and Ui.Formatting, replacing full Model/Msg dependencies with presentation data and callbacks; verify compilation and existing empty-state, pagination, and localization tests.
- [ ] 2.2 Extract Ui.PostCard and Ui.CommunityCard with callbacks and nested-content parameters; verify post display, likes, expanded replies, and community navigation through browser tests.
- [ ] 2.3 Extract Ports definitions, message encoding/decoding, and focus, dialog, and formatting commands without changing the protocol; verify compilation, JavaScript bridge tests, and dialog/localization browser tests.

## 3. Application Context and Complex Features

- [ ] 3.1 Establish App.Session and a narrow App.Context, with integration points for response wrappers and cross-feature outcomes; verify compilation and inspect dependencies to confirm features do not import Main or global Model/Msg definitions.
- [ ] 3.2 Migrate Editor modes, drafts, uploads, submission, and conflicts for standalone pages and embedded replies; verify topic/reply/edit flows, upload failures, 409 draft recovery, and exact expected_version request payloads.
- [ ] 3.3 Migrate CommunityManage state, updates, policies, roster pagination, and moderation actions, splitting files by responsibility; verify compilation and existing management browser tests for permission feedback, policy combinations, and pagination.

## 4. Account and Supporting Features

- [ ] 4.1 Migrate Auth login, registration, verification, and resend flows, connecting session, CSRF, and navigation through explicit outcomes; verify login/logout, separate login after verification, and token handling.
- [ ] 4.2 Migrate Profile public details, settings forms, and avatar uploads, preserving all three avatar states and error state; verify compilation and browser tests for profile saving and form retention after failure.
- [ ] 4.3 Migrate Search type selection, query, results, and submission navigation; verify URL query parameters and pagination retention through search browser tests and Route tests.
- [ ] 4.4 Migrate Notifications lists, counts, and read actions; verify mark-all requests use the received snapshot cursor and private state behaves correctly after session cleanup.

## 5. Content Features and Application Composition

- [ ] 5.1 Migrate Post details, direct/nested replies, likes, and deletion, using application-supplied editor content; verify post-action refreshes, confirmation dialogs, and permission feedback through discussion browser tests.
- [ ] 5.2 Migrate Feed, Community, and CommunityCreate, preserving request paths, offsets, community policies, and immutable modes; verify compilation, route tests, and community browser tests.
- [ ] 5.3 Extract App.Localization and App.Shell, preserving the localization state machine, startup/fallback, navigation, global feedback, and focus rules; verify language switching, loading failures, and accessibility through browser tests.
- [ ] 5.4 Complete Main state composition, routing coordination, centralized response validity checks, and cross-feature outcome dispatch; remove old implementations, review each item in checklist 1.1, and verify compilation.
- [ ] 5.5 Inspect line counts and imports across handwritten Elm files, split mixed responsibilities above roughly 500 lines, and confirm acyclic dependencies, no global type repository, and Main limited to coordination; deliver a module inventory with line counts.

## 6. Integration Acceptance and Documentation

- [ ] 6.1 Review existing coverage and add behavioral regressions only for uncovered critical risks; verify invalidation of old route/session/localization responses, protected-state cleanup, and editor conflict recovery, with relevant tests passing.
- [ ] 6.2 Update docs/architecture.md with module organization, state ownership, dependencies, and cross-feature events; verify consistency with actual modules and the migration checklist.
- [ ] 6.3 Run `npm run format:check`, `npm run i18n:check`, and compile, test, and build with an explicit ELM_HOME; confirm success and record baseline differences, maintaining generated files only through existing generators.
- [ ] 6.4 Start the existing development service and run `npm run test:browser` to verify forum, localization, and accessibility flows; attempt real PostgreSQL/HTTPS acceptance following docs/accessibility-and-testing.md, recording observed results separately from infrastructure limitations that prevent execution.

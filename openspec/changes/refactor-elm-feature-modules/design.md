## Context

See proposal.md for motivation. The entry module holds all feature state, while update, loadRoute, receiveLoaded, receiveAction, and pageView each branch by feature. Existing Api, Domain, Route, Locale, Localization, and Ui.Rich modules already have separate responsibilities and remain in use.

Behavior depends on route epochs, authentication generations, localization request identifiers, CSRF, browser Ports, and exact backend version numbers. Post detail embeds a reply editor, so URL boundaries alone cannot define the modules. Existing forum-application, accessible-material-interface, localized-interface, and dynamic-localization-resources specifications remain the behavioral acceptance criteria.

## Goals / Non-Goals

**Goals:**

- Keep feature state, events, response handling, and views together; leave composition and coordination to the application entry.
- Establish acyclic dependencies. Features must not import Main or depend on the complete application Model.
- Keep every migration stage compilable and preserve requests, state lifecycles, and DOM behavior.
- Target 200–400 lines per handwritten module; split responsibilities above roughly 500 lines, including Main. Do not relocate large branches into another oversized coordinator.

**Non-Goals:**

- Add no features, pages, caches, dependencies, or general plugin framework; change neither the backend nor Ports message formats.
- Do not rewrite Remote, DTO decoding, the localization state machine, the rich-content allowlist, or generated translation code.
- Do not fix existing interaction discrepancies within this refactor. Record evidence of specification conflicts and scope fixes separately.

## Decisions

### 1. Let features own state and messages

Create Auth, Feed, Community, CommunityCreate, CommunityManage, Post, Editor, Search, Notifications, and Profile under Feature. Each exposes a narrow Model, Msg, and initialization, update, loading, and view interface. Start small features as single files; organize larger features such as community management into State, Update, and View modules within a directory.

The top-level Model composes feature Models, and the top-level Msg wraps feature messages through Cmd.map and Html.map. Updates receive necessary read-only context. Views needing only a URL or translated text do not receive the entire context. Shared context must not contain all feature state.

Avoid mechanically moving global Model/Msg definitions into Types.elm, which would retain global coupling. Avoid imposing three files on every feature when they would be empty shells.

### 2. Handle cross-feature outcomes and lifecycles at the application layer

App.Session defines session and authentication state. App.Context defines necessary shared context. App.Localization coordinates the existing Localization state machine, resource loading, and activation. App.Shell renders navigation, the drawer, global feedback, and confirmation dialogs. Further separate routing coordination or outcome handling into focused App modules when needed.

Feature updates return their state, commands, and a small set of explicit outcomes, such as successful login, session expiration, navigation requests, completed post saves, or notification count changes. The application handles outcomes and dispatches required refreshes. Features do not import other features' updates to invoke them directly. Outcome types belong to their semantic owner rather than an exhaustive shared event enum.

Route transitions call feature entry or reset functions, preserving the existing loadRoute reset and draft-retention conditions without introducing a new page caching strategy.

### 3. Retain centralized asynchronous response validity checks

The application owns routeEpoch, authGeneration, and response boundaries. It validates responses before features decode and apply them. Document existing SessionLoaded, Loaded, and ActionDone checks and exceptions before migration, especially login/logout exemptions from ordinary route epoch filtering. Inject response-wrapping functions so features can call Api without depending on the top-level Msg.

Localization requests retain Pending identifiers and Localization checks, separately from page epochs. The application coordinates feature resets when a 401 clears protected state. Preserve 403 feedback, 409 draft and version conflict handling, and the absence of automatic mutation retries.

Do not duplicate epoch checks across features, where rules could diverge.

### 4. Reuse the editor and shared presentation independently

Editor owns modes, drafts, attachments, upload/save state, original versions, and conflicts. The application coordinates standalone editor pages and embedded reply editors. Post views receive editor Html through parameters or slots to avoid circular Post/Editor dependencies.

Ui.PostCard, Ui.CommunityCard, Ui.Feedback, Ui.Pagination, and Ui.Formatting receive presentation data and event callbacks, return Html msg, and own no HTTP state. Expanded replies use explicit data/content parameters; callers map like and reply events.

Ports.elm centralizes outgoing/incoming definitions, protocol encoding/decoding, and focus, dialog, and formatting commands. Preserve JavaScript message structures and subscriptions. App modules and features depend on Ports; Ports does not import Main.

### 5. Validate behavioral equivalence and explicitly skip specs

There are no specification-level behavior changes. Declare skip_specs in metadata rather than inventing an architecture capability. Review responsibility ownership, dependency direction, and file size. Tests check behavior rather than filenames or internal function structure.

Reuse Elm, JavaScript, forum browser, and localization browser tests. Add tests only for uncovered asynchronous invalidation, session cleanup, or editor conflict behavior with clear migration risk. Preserve URLs, request payloads, exact expected_version numbers, status/error feedback, CSS classes, focus IDs, accessible names, and DOM hooks.

## Risks / Trade-offs

- [Message mapping and outcomes add boilerplate] → Use them at actual boundaries, keep local events inside features, and avoid a general effect interpreter framework.
- [Old responses modify new state across module boundaries] → Document generation rules, validate at centralized response boundaries, and add necessary behavioral regressions.
- [State reorganization changes draft or form lifecycles] → Compare against original loadRoute, clearPrivate, and conflict branches; verify route transitions and recoverable errors.
- [Shared cards or the shell change accessibility] → Preserve semantic elements, focus targets, dialogs, and test hooks; run browser acceptance checks.
- [Main or shared types remain oversized] → Review all handwritten Elm files and further separate coordination responsibilities rather than simply relocating code.
- [Real-backend acceptance needs external infrastructure] → Distinguish simulated browser tests from real PostgreSQL/HTTPS acceptance. Report unavailable checks without claiming they passed.

## Migration Plan

1. Record routing, asynchronous rules, state lifecycles, and test baselines; extract shared presentation and Ports first.
2. Introduce narrow context and session types, then migrate Editor and CommunityManage. Remove their old implementations and compile after each migration.
3. Migrate Auth, Profile, Search, and Notifications, then Post, Community, Feed, and CommunityCreate.
4. Finish application localization, shell, routing, and cross-feature coordination. Remove superseded global branches and helper types, and update architecture documentation.
5. Run formatting, translation consistency, compilation, unit tests, builds, and browser regressions. Attempt real-backend acceptance following docs/accessibility-and-testing.md and report infrastructure limitations.

No data or service migration is required; deployment remains unchanged. Roll back to the previous working frontend build. Revert code by validated migration batches without restoring or overwriting unrelated user changes.

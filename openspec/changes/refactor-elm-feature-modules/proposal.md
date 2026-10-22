## Why

`src/Main.elm` has grown to 4260 lines, combining sessions, routing, all feature state, response handling, and rendering. Organizing code by feature will keep related state and updates together, narrow change scope, and reduce regressions across features.

## What Changes

- Split authentication, feeds, communities, community creation, community management, posts, the editor, search, notifications, and profiles into modules owning their state, messages, updates, and views.
- Extract application session handling, shared context, localization coordination, and the shell, alongside Ports, shared cards, feedback, pagination, and formatting.
- Limit Main to startup, top-level state composition, routing coordination, message dispatch, and cross-feature events, retaining centralized asynchronous response generation checks.
- Reuse an independent editor for topics, replies, and edits; subdivide larger features by responsibility.
- Target 200–400 lines per handwritten module; review and split responsibilities above roughly 500 lines. Exclude generated code.
- Update architecture documentation and verify behavioral equivalence with existing checks and necessary regression tests.

## Capabilities

### New Capabilities

None. This refactor preserves behavior, sets `skip_specs: true`, and creates no delta specs.

### Modified Capabilities

None. Existing forum, accessibility, and dynamic localization specifications remain applicable. Routing, API, permission, and interaction requirements remain unchanged.

## Impact

- Affects `src/Main.elm`, new `App/`, `Feature/`, and shared `Ui/` modules, `Ports.elm`, related tests, and `docs/architecture.md`.
- Preserves the responsibilities of Api, Domain, Route, Locale, Localization, and Ui.Rich. Translation files remain maintained by existing generators.
- Adds no dependencies and changes no backend code, HTTP contracts, browser storage, JavaScript bridge protocols, styles, or user-visible behavior.

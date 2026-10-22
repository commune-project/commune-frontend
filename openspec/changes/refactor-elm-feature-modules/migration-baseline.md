# Migration Baseline

Recorded on 2026-10-22 before source changes, against commit `5dd9c84`.

## State and Response Checklist

- `UrlChanged` increments routeEpoch, closes the drawer and confirmation state, invokes loadRoute, refreshes unread count when authenticated, and requests heading focus. RetryPage also increments routeEpoch before loading.
- loadRoute resets topics, communities, community details/topics, post, replies, nested replies, expanded replies, public/own profile reads, notifications, unread count, source, editor, and management state. It does not globally reset authentication forms, profileForm, or createCommunity.
- Latest and community lists load offset-based pages. Community detail loads its details and topics together. Post detail loads the post and direct replies together.
- NewCommunity resets its form. NewTopic initializes a fresh editor and loads the target community. EditPost loads the source before populating the editor. Login, Register, Verify, and NotFound perform only the shared route reset.
- Search reconstructs kind and query from the URL, normalizes unsupported kinds to posts, and does not request empty queries. Notifications, Settings, and Manage load protected data only for authenticated sessions. Manage initializes both roster offsets to zero.
- SessionLoaded accepts only the current authGeneration. Loaded accepts only the current routeEpoch. ActionDone rejects mismatched route epochs except for LoginAction and LogoutAction.
- Successful login advances authGeneration and routeEpoch, clears the password, navigates home, and requests CSRF. Successful logout advances both generations, clears CSRF and protected state, navigates to login, and requests CSRF.
- authProblem handles 401 by switching to Anonymous, advancing authGeneration, clearing CSRF, displaying the problem, and calling clearPrivate. clearPrivate resets ownProfile, notifications, unreadCount, profileForm, manage, and busy. Preserve this exact existing boundary rather than silently expanding it.
- Recoverable upload/save failures preserve draft text. An edit_conflict 409 retains the editor and requests the latest source. ReloadSourceAction stores conflict source without overwriting the draft. EditorUseLatest replaces fields and version from conflict source; EditorKeepDraft clears the conflict while retaining the draft.
- Preserve source-backed editing, exact numeric expected_version payloads, attachment identifiers, existing policy normalization, snapshot cursors for mark-all-read, and the absence of automatic mutation retries.
- Localization uses its existing Pending identifiers independently of routeEpoch. Incoming formatting is accepted only for the active locale. Preserve resource identity, fallback, focus, dialog, and JavaScript bridge behavior.

## Baseline Results

- `ELM_HOME=/tmp/commune-elm-home npm run compile`: failed before compilation because the installed pnpm Elm launcher invokes Node on the native ELF executable.
- `ELM_HOME=/tmp/commune-elm-home node_modules/elm/bin/elm make src/Main.elm --output=/tmp/commune-baseline.js`: passed.
- `node --test tests-js/*.test.js`: passed all four test files.
- `ELM_HOME=/tmp/commune-elm-home node node_modules/elm-test/bin/elm-test --compiler ./node_modules/elm/bin/elm`: passed all 20 tests with network access enabled. The sandboxed attempt could not load the package index through the configured proxy.
- Started Vite directly with `node node_modules/vite/bin/vite.js --host 127.0.0.1 --port 4173` and ran `node node_modules/@playwright/test/cli.js test`: 36 passed, one real-backend test skipped because isolated services/credentials were not configured. Server and browser execution required sandbox escalation.
- Browser baseline used the existing public/elm.js served by Vite; the independently compiled baseline artifact was written to /tmp.

## Tooling Issue and Resolution

The original node_modules/.bin/elm launcher executed Node with elm/bin/elm as a JavaScript input, but that file is a native executable. Direct compilation and tests succeeded using the native compiler path. This was the pre-refactor tooling failure, not an Elm source failure.

Following explicit authorization to fix startup, pnpm-workspace.yaml now permits the elm, elm-format and esbuild install scripts with boolean allowBuilds values. Running `pnpm rebuild elm elm-format esbuild` regenerated native launchers. Standard compile, dev, test, format and build commands work again. The unrelated pnpm-lock.yaml was left unchanged.

## Lifecycle Review Clarifications

The checklist describes calls to authProblem, not a new blanket rule for every HTTP 401. In the original code, profile save/avatar upload and community creation failures only update their local forms; the refactor preserves that behavior. The new profile regression verifies a failed save retains the draft, then a page-read 401 expires the session and clears the retained private form. A subsequent unsuccessful profile read cannot recover that draft.

All route resets, authentication generation transitions, login/logout epoch exemptions, conflict reload/version handling, snapshot cursors, and browser message shapes were compared with the pre-refactor implementation. Final verification and the complete module inventory are recorded in validation.md.

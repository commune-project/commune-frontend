# Refactor Validation

Validated on 2026-10-22 for `refactor-elm-feature-modules`.

## Results

| Check | Observed result |
| --- | --- |
| `npm run format:check` | Passed. |
| `npm run i18n:check` | Passed; generated catalogs/assets are current. |
| `ELM_HOME=/tmp/commune-elm-home npm run compile` | Passed with the standard native launcher. |
| `ELM_HOME=/tmp/commune-elm-home npm test` | 11 JavaScript tests and 20 Elm tests passed. |
| `ELM_HOME=/tmp/commune-elm-home npm run build` | Optimized Elm compilation and Vite production build passed. |
| `ELM_HOME=/tmp/commune-elm-home npm run dev -- --port 4173` | Standard script generated translations, compiled Elm and started Vite. An existing server occupied 4173, so this invocation selected 4174 and was stopped; browser checks used the existing 4173 development server and the newly compiled public/elm.js. |
| `npm run test:browser` | 39 passed, one real-backend test skipped. Includes forum, localization and automated accessibility checks. |
| Explicit real-backend attempt with `COMMUNE_REAL_BACKEND=1 COMMUNE_TEST_URL=https://localhost:8443 ./node_modules/.bin/playwright test tests-browser/real-backend.spec.js` | One skipped by the credential guard; neither real-account password was configured. HTTPS probe also found no service on localhost:8443. PostgreSQL/HTTPS workflows were not verified in this run. |
| Import and size inspection | 48 handwritten modules, no dependency cycles, no Feature imports of Main or aggregate application state/coordinators; largest module 401 lines. |
| `git diff --check` | Passed. |

Generated translation source and assets were maintained through the existing generator. Api, Domain, Route, Remote, Locale, Localization and Ui.Rich retain their original implementations.

Compared with the baseline, standard launcher commands now succeed after fixing pnpm allowBuilds and rebuilding native tools. All 36 existing simulated browser tests still pass; three behavioral regressions were added. No new dependencies, backend endpoints, port message formats or specification behavior were introduced.

## Regression Coverage

- An old post-read 401 arriving after route navigation cannot expire the current session.
- A delayed startup session response arriving after login and logout cannot restore private authentication state.
- A failed profile save retains its draft as before; a later page-read 401 clears that private draft, and a failed settings read after login cannot restore it.
- Existing localization tests cover superseded catalog responses, resource identity, malformed replacements, startup fallback, focus and recovery.
- Existing editor tests cover source-backed editing, exact expected_version payloads, upload failure retention and 409 source/draft recovery.
- Existing forum tests cover nested replies, likes, deletion/dialog focus, policies/rosters, notification snapshot cursors, avatars, request endpoints and error presentation.

The route-reset and clearPrivate checklist in migration-baseline.md was reviewed against App.Routing, App.Access and feature adapters, including the original local-form-error exceptions. Manual assistive technology and real keyboard/IME checks retain the limitations documented in docs/accessibility-and-testing.md.

## Handwritten Module Inventory

Line counts include module headers, imports and blank lines, excluding the final newline. Generated.I18n is excluded. Small semantic types and adapters intentionally remain below the 200–400 line guideline; no handwritten module exceeds roughly 500 lines.

| File | Lines |
| --- | ---: |
| `src/Api.elm` | 84 |
| `src/App/Access.elm` | 30 |
| `src/App/Browser.elm` | 31 |
| `src/App/Context.elm` | 10 |
| `src/App/Features.elm` | 364 |
| `src/App/Feedback.elm` | 52 |
| `src/App/Init.elm` | 91 |
| `src/App/Interaction.elm` | 55 |
| `src/App/Localization.elm` | 143 |
| `src/App/Routing.elm` | 154 |
| `src/App/Session.elm` | 9 |
| `src/App/Shell.elm` | 272 |
| `src/App/State.elm` | 97 |
| `src/App/View.elm` | 177 |
| `src/App/View/Account.elm` | 60 |
| `src/App/View/Content.elm` | 118 |
| `src/App/View/Participation.elm` | 65 |
| `src/Domain.elm` | 256 |
| `src/Feature/Auth/State.elm` | 38 |
| `src/Feature/Auth/Update.elm` | 229 |
| `src/Feature/Auth/View.elm` | 172 |
| `src/Feature/Community.elm` | 188 |
| `src/Feature/CommunityCreate.elm` | 211 |
| `src/Feature/CommunityManage/State.elm` | 116 |
| `src/Feature/CommunityManage/Update.elm` | 401 |
| `src/Feature/CommunityManage/View.elm` | 346 |
| `src/Feature/Editor/State.elm` | 58 |
| `src/Feature/Editor/Update.elm` | 351 |
| `src/Feature/Editor/View.elm` | 177 |
| `src/Feature/Feed.elm` | 86 |
| `src/Feature/Notifications.elm` | 241 |
| `src/Feature/Post.elm` | 316 |
| `src/Feature/Profile.elm` | 332 |
| `src/Feature/Search.elm` | 203 |
| `src/Locale.elm` | 119 |
| `src/Localization.elm` | 140 |
| `src/Main.elm` | 241 |
| `src/Ports.elm` | 97 |
| `src/Remote.elm` | 46 |
| `src/Route.elm` | 143 |
| `src/Ui/CommunityCard.elm` | 33 |
| `src/Ui/CommunityPolicy.elm` | 34 |
| `src/Ui/Feedback.elm` | 107 |
| `src/Ui/Formatting.elm` | 119 |
| `src/Ui/Layout.elm` | 12 |
| `src/Ui/Pagination.elm` | 34 |
| `src/Ui/PostCard.elm` | 124 |
| `src/Ui/Rich.elm` | 74 |

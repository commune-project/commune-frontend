## Why

The application bar currently carries the brand, primary navigation, account actions, language selection, and localization status in one sticky row. On wide screens that row consumes vertical space and forces unrelated controls into a single line that wraps at enlarged text sizes. On compact widths the drawer duplicates the navigation while language and identity stay in the bar, so the same destinations appear in two different places. Material Design 3 keeps a top app bar for branding and a single menu affordance, and places primary destinations in a navigation drawer.

## What Changes

- Reduce the top app bar to a 64dp branded surface containing only the menu button and the Commune wordmark.
- Introduce a 360dp navigation drawer that is permanent at 1200 CSS pixels and wider, and modal below that width.
- Move the primary destinations (Latest, Communities, Search, Notifications), account actions (Profile, Settings, Log out or Log in), language selection, and localization pending state into the drawer.
- Add a drawer profile header on the brand gradient with the user avatar, display name, `@username`, and administrative role. Anonymous visitors see a sign-in entry instead.
- Present the unread notification count as a trailing badge while keeping the localized notification text as the accessible name.
- Make the wide-screen menu button collapse and expand the permanent drawer; the collapsed state is not persisted across reloads.
- **BREAKING** (interface only): the top bar no longer exposes navigation, language, or account controls. Tests and documentation that target `#language-select` or the `Main navigation` landmark inside the bar must target the drawer instead.
- Out of scope: user-customizable drawer backgrounds. The header keeps the existing brand gradient because the backend has no profile background field.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `accessible-material-interface`: narrows the application bar to brand and menu affordances, and adds the permanent and modal navigation drawer, its breakpoint, profile header, account section, notification badge, and viewport-driven layout switching.

## Impact

- `src/App/Shell.elm` for the app bar and drawer views, `src/App/State.elm` for layout and drawer state, `src/App/Init.elm` and `src/Main.elm` for the viewport signal and session profile load, `src/App/Routing.elm` so route changes do not clear the drawer profile.
- `src/style.css` for the shell grid, app bar, drawer, active indicator, badge, forced-colors rules, and scroll padding; `src/bootstrap.js` for the `matchMedia` flag and resize notification.
- `scripts/generate-icons.mjs`, `src/Generated/Icons.elm`, and `src/Ui/Icon.elm` for the navigation icon set.
- The existing `/api/v1/profile` endpoint supplies the drawer identity. No backend or API change is required.
- `tests-browser/localization.spec.js` and `tests-browser/forum.spec.js` need updated navigation targets and new permanent/collapsed drawer coverage.
- No new dependencies.

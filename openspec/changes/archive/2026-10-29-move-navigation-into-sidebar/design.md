## Context

See proposal.md for motivation and the delta spec for observable requirements.

The current shell is a single column: a sticky `.top-bar` carries the menu button, wordmark, `navLinks`, the language select, the signed-in label, and the pending indicator; `.page-grid` centres a 760px content column. A modal `<dialog id="navigation-drawer">` reuses `navLinks` only below 600px. There is no viewport signal in Elm: `Flags` contains `languages`, `savedLocale`, `csrf`, and `verificationToken`, and nothing listens to resize or `matchMedia`.

Identity data is split. `Domain.Identity` carries `username`, `actor`, `siteAdmin`, and `deploymentAdmin`; the avatar, display name, and biography live only in `Domain.Profile`, fetched from `/api/v1/profile`. `App.Routing.loadRoute` resets `Feature.Profile.Model` on every navigation, so profile data placed there cannot back a persistent drawer header. The backend has no custom background field.

## Goals / Non-Goals

**Goals:**

- One drawer definition that serves both the permanent and modal presentations, with one source of truth for destinations.
- A layout switch that follows `matchMedia` precisely, including the first paint.
- A drawer header that keeps its profile data for the whole authenticated session.
- Keep the existing brand gradient and its measured contrast, including the drawer header.

**Non-Goals:**

- Persisting the drawer collapse state or the selected language in a new store.
- User-customizable drawer backgrounds, avatar cropping, or banner uploads.
- Changing the API, the session payload, or any backend behavior.
- Introducing a navigation rail at intermediate widths.

## Decisions

### D1. Viewport mode arrives through `matchMedia`, not through duplicated DOM

`src/bootstrap.js` will evaluate `window.matchMedia('(min-width: 1200px)')` once, pass the boolean in the init flags, and subscribe to its `change` event, forwarding `{ kind: "layout", wide: ... }` through the existing incoming port. `App.State.Model` gains `wideLayout : Bool`, decoded from the flag and updated by the port message.

Alternative considered: render both a permanent drawer and a modal drawer and hide one with `display: none`. Rejected because the two trees would duplicate `#language-select`, the `Main navigation` landmark, and the destination ids, and because focus restoration would have two possible targets.

Alternative considered: listen to `resize` and compare `innerWidth`. Rejected because it fires continuously during a drag, forces a re-render per pixel, and can disagree with the CSS breakpoint during zoom.

### D2. One `drawerOpen` flag, interpreted per mode, reset on mode change

`drawerOpen` keeps its current meaning on compact widths (modal visibility). On wide widths it means "permanent drawer expanded". The flag is not persisted. When `wideLayout` changes, the model resets it to the mode default: `True` for wide, `False` for compact. That avoids the failure where a modal stays open over a permanent layout, or a desktop collapse silently carries into a phone viewport.

Alternative considered: separate `drawerOpen` and `drawerCollapsed` fields. Rejected because two booleans can contradict each other after a breakpoint change and every view branch has to decide which one wins.

Alternative considered: keep the collapsed state in `localStorage` alongside the locale. Rejected for this change: the spec requires the default on reload, and a persisted collapse would make screenshots and acceptance runs depend on prior interaction.

### D3. Drawer profile data lives on the app model and loads once per session

`App.State.Model` gains `drawerProfile : Remote Domain.Profile`. `SessionLoaded` with `Ok identity` issues `Api.get "/api/v1/profile"`; the response populates `drawerProfile`. Logout, session expiry, and `401` set it back to `NotAsked`. `Brand`/`anonymous` sessions leave it empty. The route loader does not touch this field.

The drawer header renders `profile.name` as the display name, `@` plus `profile.username` (or `identity.username`) as the secondary line, and the existing `siteAdministrator` / `deploymentAdministrator` labels joined with a separator. While the request is pending or failed, the header shows a circular placeholder with the first character of the username and keeps the username text. The avatar image is decorative (`alt=""`) because the adjacent name carries the identity.

Alternative considered: keep using `Feature.Profile.ownProfile` and stop resetting it in `App.Routing`. Rejected because the settings form is rebuilt from that model and expects a fresh load per visit; sharing it would couple an editable form to a persistent navigation header.

### D4. Permanent and modal drawers are separate render branches, not one `<dialog>`

At wide widths the drawer renders as an `<aside>` containing a `<nav aria-label="Main navigation">` inside the shell grid. At compact widths it renders as the existing `<dialog>` with `showModal()`, Escape handling, focus containment, and focus restoration to `#menu-button`. The two branches share `drawerContent`, so destinations, ordering, and the profile header cannot drift.

Alternative considered: always render a `<dialog>` and override its display at wide widths. Rejected because a permanent navigation region must not carry `role="dialog"`, trap focus, or sit behind a backdrop.

### D5. The shell becomes a two-column grid below the app bar

`.app-shell` keeps the sticky 64dp app bar across the full width. Below it, a `.shell-body` grid uses `grid-template-columns: 360px minmax(0, 1fr)` at 1200px and wider, and `minmax(0, 1fr)` below. The drawer is `position: sticky; inset-block-start: 64px; max-height: calc(100dvh - 64px); overflow-y: auto`. The content column keeps `width: min(100% - 4rem, 760px); margin-inline: auto`. Collapsing the drawer switches the grid to one column and removes the drawer from the layout.

The existing `.page-grid` class on `<main>` is retired or reduced to the content-column rules; it must not keep `justify-content: center` in a way that offsets the column against the drawer.

### D6. The app bar keeps only the menu affordance and wordmark

The bar becomes 64dp high with one leading `.icon-button` and the `.brand` link. The language select, identity label, pending label, and `desktop-nav` leave the bar entirely. The skip link moves inside the bar as the first focusable element and expands into a full-width overlay when focused, so it never sits on top of the menu button. `scroll-padding-block-start` drops from `6rem` to `4rem` plus a small margin.

The bar and the drawer header share the existing `--md-top-bar-start/mid/end` and `--md-on-top-bar` tokens. A 1px separator line distinguishes the drawer header from the bar when both use the same gradient, so the two surfaces do not read as one undifferentiated block.

### D7. Drawer items use a primary-container indicator

Each destination is a 56px minimum-height row with a 24px decorative icon, a 16px label, and a pill-shaped indicator on the current destination. The indicator uses `--md-primary-container` with `--md-on-primary-container` text, which already exists and clears 4.5:1. Current state also carries bold weight and `aria-current="page"`, so color is not the only cue. Notification count is a text badge after the label; the accessible name remains the localized `Notifications (n)` phrase.

The footer holds the language `<label>` + `<select id="language-select">` and the pending label on the surface background, with a top separator. In the modal drawer this footer scrolls with the drawer content rather than being pinned, avoiding a second scroll container at 320px.

### D8. Icon data expands through the existing generator

`scripts/generate-icons.mjs` gains `home`, `groups`, `search`, `notifications`, `person`, `settings`, `logout`, `login`, `language`, `menu`, and `close`. Each source file has a single `<path>` in `@material-design-icons/svg 0.14.15`, so the generator's one-path assertion still holds. `Ui.Icon` gains matching variants; all icons remain `aria-hidden="true"` and `focusable="false"`.

### D9. Accessibility behavior is preserved rather than reimplemented

The compact drawer keeps the native `<dialog>` so focus containment, Escape, and the backdrop come from the platform. The wide drawer is ordinary document content, so no focus trap is applied and the tab order follows the visual order: skip link, menu button, wordmark, drawer destinations, account actions, language selector, then main content. SPA navigation keeps the existing "focus `main-heading`" behavior.

The 64dp app bar and 360dp drawer mean the fixed skip link no longer overlaps a top-left menu control once it is inside the bar. At 200% text the drawer labels wrap and rows grow in height instead of truncating.

### D10. Acceptance updates target the new locations

`tests-browser/localization.spec.js` opens the drawer before asserting `#language-select` at 768px; the 1280px cases continue to see it in the permanent drawer. A new case asserts that the wide menu button collapses the drawer, expands the content column, and does not navigate. The existing 320px modal focus test remains valid.

## Risks / Trade-offs

- **Breakpoint jump at 1200px** → the layout changes in one step, and a modal does not survive the crossing. Mitigation: `matchMedia` change events, reset to the mode default, and an e2e case that resizes across the boundary.
- **Profile fetch failure removes identity from the drawer** → the header falls back to a username placeholder and the account destinations stay usable. Mitigation: placeholder plus the existing session flash behavior.
- **Language switching inside a modal drawer re-renders the catalog** → the drawer could lose focus or close. Mitigation: keep `drawerOpen` independent of the catalog, keep `#language-select` stable, and assert focus in the 768px e2e case.
- **Sticky bar plus a sticky drawer inside a grid** → sticky positioning breaks if an ancestor clips overflow. Mitigation: keep `.app-shell` and `.shell-body` free of `overflow: hidden`, and verify scroll behavior at 400% zoom.
- **360px drawer at 200% text** → labels wrap into taller rows and the drawer may need more height than the viewport. Mitigation: drawer content scrolls; no fixed row heights.
- **Permanent drawer reduces the content area at 1200px** → the content column stops growing and the discussion column keeps 760px. This is the intended trade-off; below 1200px the modal drawer restores the full width.
- **Custom backgrounds remain unavailable** → users cannot brand the drawer header beyond the product gradient until a backend field exists. Recorded as a non-goal rather than faked with local-only state.

## Migration Plan

1. Add the viewport flag and `matchMedia` message; no visible change.
2. Add the drawer profile load and state; no visible change until the new view is rendered.
3. Add the icon set and `Ui.Icon` variants.
4. Replace the shell views and CSS together, because the bar and drawer must change in the same paint to avoid a transition where navigation is absent.
5. Update the browser tests and run the full accessibility scan.

Rollback is a revert of the change: the previous shell has no persisted state, so no data migration is required.

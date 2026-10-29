## 1. Viewport signal and layout state

- [ ] 1.1 In `src/bootstrap.js`, evaluate `window.matchMedia('(min-width: 1200px)')`, pass its `matches` value in the init flags, and forward `{ kind: "layout", wide }` on change; verify the page initializes and toggling the viewport in DevTools emits one message per crossing.
- [ ] 1.2 Decode the layout flag and message in `src/App/Init.elm` and `src/Ports.elm`, add `wideLayout : Bool` to `App.State.Model`, and handle the incoming message in `src/Main.elm`; verify `npm run compile` succeeds and `elm-test` still passes.
- [ ] 1.3 Reset `drawerOpen` to the mode default when `wideLayout` changes, and add an elm-test case covering wide expanded, compact closed, and breakpoint crossing; verify the new test fails before the change and passes after.

## 2. Drawer identity data

- [ ] 2.1 Add `drawerProfile : Remote Domain.Profile` to `App.State.Model` and request `/api/v1/profile` after `SessionLoaded` succeeds; verify a signed-in load populates the field once in the Elm debugger or a temporary log.
- [ ] 2.2 Clear `drawerProfile` on logout, session expiry, and `401`, and leave it untouched by `App.Routing.loadRoute`; verify navigating across three routes keeps the header data and logging out empties it.
- [ ] 2.3 Render the header fallback for pending, failed, and empty profiles using the first username character and the visible username; verify a failed profile request still shows a usable drawer header.

## 3. Navigation icons

- [ ] 3.1 Extend `scripts/generate-icons.mjs` with `home`, `groups`, `search`, `notifications`, `person`, `settings`, `logout`, `login`, `language`, `menu`, and `close`, then run `npm run icons:generate`; verify `src/Generated/Icons.elm` exposes all eleven names and keeps the generated header.
- [ ] 3.2 Add matching variants to `src/Ui/Icon.elm` and confirm every rendered icon stays `aria-hidden="true"` and `focusable="false"`; verify `npm run compile` succeeds.

## 4. Shell views and styles

- [ ] 4.1 Refactor `src/App/Shell.elm` so the app bar contains only the menu button and wordmark, and extract a shared `drawerContent` used by a permanent `<aside>` and the compact `<dialog>`; verify compile and that both modes list the same destinations in the same order.
- [ ] 4.2 Replace the `.top-bar` layout rules in `src/style.css` with a 64dp bar, a `.shell-body` grid of `360px minmax(0, 1fr)` at 1200px and wider, and a one-column grid below; verify 1280, 768, and 320px render without page-level horizontal scrolling.
- [ ] 4.3 Style drawer destinations, the 24px icons, the 56px minimum row height, the `--md-primary-container` active indicator with bold text, the notification badge, the separator, and the language footer; verify the current destination is distinguishable with color disabled.
- [ ] 4.4 Move the skip link into the app bar as the first focusable element and expand it on focus; verify it does not cover the menu button and still targets `#main-content`.
- [ ] 4.5 Update forced-colors, reduced-motion, scroll-padding, and 200% text rules for the new shell; verify `prefers-reduced-motion` and `forced-colors: active` e2e cases pass.

## 5. Accessibility behavior

- [ ] 5.1 Verify tab order is skip link, menu button, wordmark, drawer destinations, account actions, language selector, then main content, and that the wide drawer applies no focus trap; record the manual keyboard check.
- [ ] 5.2 Verify the compact drawer keeps native `<dialog>` focus containment, closes on Escape and destination activation, and restores focus to `#menu-button`; extend the existing 320px browser test.
- [ ] 5.3 Verify drawer header text and icons keep at least 4.5:1 against the lightest gradient stop and the avatar boundary at least 3:1; record the measured ratios.
- [ ] 5.4 Verify the drawer survives 200% text, 400% zoom, and WCAG text-spacing overrides without clipping or overlapping the app bar; run the existing enlarged-text browser test with the drawer open.

## 6. Browser tests and final verification

- [ ] 6.1 Update `tests-browser/localization.spec.js` so the 768px case opens the drawer before asserting `#language-select`, and add a case for wide collapse/expand plus reload defaults; verify `npx playwright test tests-browser/localization.spec.js` passes.
- [ ] 6.2 Confirm the 320px modal focus test and the 1280px RTL and forced-colors cases still pass after the selector changes; verify `npx playwright test tests-browser/forum.spec.js`.
- [ ] 6.3 Run the automated accessibility scan across every implemented page at 1280, 768, and 320px and confirm zero WCAG 2.0/2.1/2.2 A/AA violations; record the result in the verification notes.
- [ ] 6.4 Run `npm run format:check`, `npm test`, `npm run compile`, and `npm run test:browser`; confirm all pass before requesting review.

## 1. Palette tokens

- [ ] 1.1 Add `--md-top-bar-start`, `--md-top-bar-mid`, `--md-top-bar-end`, `--md-on-top-bar`, `--md-focus-on-dark`, `--md-accent`, and `--md-accent-soft` to the `:root` block in `src/style.css`, each with the measured contrast ratio in an inline comment; verify all seven resolve in the browser devtools computed style and that no component-level hex value was introduced
- [ ] 1.2 Confirm the existing purple base tokens (`--md-primary`, `--md-primary-container`, `--md-on-primary-container`, `--md-surface`, `--md-surface-container`, `--md-surface-container-high`, `--md-on-surface`, `--md-on-surface-variant`, `--md-outline`, `--md-error`, `--md-focus`, `--md-elevation-1`) keep their current values; verify by diffing the `:root` block and confirming only additions

## 2. Application bar surface and foreground

- [ ] 2.1 Replace the `.top-bar` background with an opaque `linear-gradient(100deg, var(--md-top-bar-start) 0%, var(--md-top-bar-mid) 55%, var(--md-top-bar-end) 100%)` and remove the `color-mix` expression; verify the computed `background-image` is a gradient and that no alpha channel appears in the computed value
- [ ] 2.2 Set `.brand`, `.top-bar nav a`, `.top-bar .link-button`, `.top-bar .icon-button`, `.top-bar .identity-label`, and `.top-bar .pending-label` to `var(--md-on-top-bar)` without opacity; verify each computed color is `rgb(255, 255, 255)` and that no top-bar descendant declares `opacity` below 1
- [ ] 2.3 Replace the color-only current-page signal with bold weight plus a 3px `var(--md-on-top-bar)` underline on `.top-bar nav a[aria-current="page"]`; verify the underline is visible while the link is not focused and that `aria-current="page"` is still emitted by `navLink` in `src/App/Shell.elm`
- [ ] 2.4 Keep the compact-width wrapping behavior intact at 320 CSS pixels; verify the bar, language control, and menu button wrap without overlap and without horizontal page scrolling

## 3. Focus, skip link, and in-bar controls

- [ ] 3.1 Add a `.top-bar :focus-visible` rule using a 3px `var(--md-focus-on-dark)` outline with the existing 3px offset; verify by tabbing through every bar control that the ring is visible against both the gradient and any light-filled control
- [ ] 3.2 Repaint `.skip-link` as a light surface with `var(--md-primary)` text; verify it becomes visible on focus at the top inline-start corner and that its boundary is distinguishable from the bar
- [ ] 3.3 Give the in-bar language `select` a boundary that reaches at least 3:1 against the gradient (white border or none plus a light fill) while keeping dark text on the light fill; verify the select remains identifiable in both LTR and RTL without relying on the border alone
- [ ] 3.4 Add a `forced-colors: active` fallback so the application bar keeps a perceivable boundary (`CanvasText`) when the gradient is replaced; verify with Chromium forced-colors emulation that the bar, focus ring, and current-page indicator remain distinguishable

## 4. Accent usage on light surfaces

- [ ] 4.1 Apply `var(--md-accent)` to the notice inline-start border, chip outlines, and section eyebrow text on light surfaces; verify no accent token is applied inside `.top-bar` and that no small accent text falls below 4.5:1
- [ ] 4.2 Confirm `--md-accent-soft` is used only for decorative or large-bold labels and never for body-size text or as a background behind body-size text; verify by searching `src/style.css` for every `--md-accent-soft` usage
- [ ] 4.3 Confirm destructive controls still use `var(--md-error)` and retain their text labels; verify `.danger-button`, `.danger-text`, `.field-error`, and `.conflict-panel` are untouched

## 5. Metadata and evidence

- [ ] 5.1 Update the `theme-color` meta in `index.html` to the mid-gradient value `#5a55c0`; verify by reading the built `index.html` served by the preview
- [ ] 5.2 Record the palette, the per-stop white-text ratios, and the manual checks that automated scans cannot cover in `docs/accessibility-and-testing.md`; verify the document names the browser used, the forced-colors result, and any remaining unverified combinations

## 6. Automated contrast guard

- [ ] 6.1 Add `tests-js/palette.test.js` that reads `src/style.css`, extracts the palette tokens, and computes WCAG relative luminance and contrast ratios; verify it asserts at least 4.5:1 for white on each of the three top-bar stops, 4.5:1 for `--md-on-top-bar` on each stop, 4.5:1 for `--md-accent` on `--md-surface`, 3:1 for `--md-focus-on-dark` on each stop, and 4.5:1 for `--md-error` on `--md-surface`
- [ ] 6.2 Run `node --test tests-js/*.test.js` and confirm the new guard passes alongside the existing JavaScript tests; verify a deliberately lightened stop makes the guard fail before restoring the correct value

## 7. Verification

- [ ] 7.1 Run `ELM_HOME=/tmp/commune-elm-home npm run build` and confirm the production build succeeds and the generated CSS contains the new tokens
- [ ] 7.2 Run `npm run test:browser` against the dev server and confirm all existing axe WCAG 2.2 AA checks still report zero violations on the routes that render the bar
- [ ] 7.3 Manually verify 200% text resize, 400% zoom at 1280 CSS pixels, reduced motion, and forced colors on the feed, a topic, and the compact drawer; confirm the bar never obscures content or focus
- [ ] 7.4 Run `openspec validate adopt-blue-purple-header-palette --strict` and confirm the change validates

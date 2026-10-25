## 1. Palette tokens

- [x] 1.1 Add `--md-top-bar-start`, `--md-top-bar-mid`, `--md-top-bar-end`, `--md-on-top-bar`, `--md-focus-on-dark`, `--md-accent`, and `--md-accent-soft` to the `:root` block in `src/style.css`, each with the measured contrast ratio in an inline comment; verify all seven resolve in the browser devtools computed style and that no component-level hex value was introduced
- [x] 1.2 Confirm the existing purple base tokens (`--md-primary`, `--md-primary-container`, `--md-on-primary-container`, `--md-surface`, `--md-surface-container`, `--md-surface-container-high`, `--md-on-surface`, `--md-on-surface-variant`, `--md-outline`, `--md-error`, `--md-focus`, `--md-elevation-1`) keep their current values; verify by diffing the `:root` block and confirming only additions

## 2. Application bar surface and foreground

- [x] 2.1 Replace the `.top-bar` background with an opaque `linear-gradient(100deg, var(--md-top-bar-start) 0%, var(--md-top-bar-mid) 55%, var(--md-top-bar-end) 100%)` and remove the `color-mix` expression; verify the computed `background-image` is a gradient and that no alpha channel appears in the computed value
- [x] 2.2 Set `.brand`, `.top-bar nav a`, `.top-bar .link-button`, `.top-bar .icon-button`, `.top-bar .identity-label`, and `.top-bar .pending-label` to `var(--md-on-top-bar)` without opacity; verify each computed color is `rgb(255, 255, 255)` and that no top-bar descendant declares `opacity` below 1
- [x] 2.3 Replace the color-only current-page signal with bold weight plus a 3px `var(--md-on-top-bar)` underline on `.top-bar nav a[aria-current="page"]`; verify the underline is visible while the link is not focused and that `aria-current="page"` is still emitted by `navLink` in `src/App/Shell.elm`
- [x] 2.4 Keep the compact-width wrapping behavior intact at 320 CSS pixels; verify the bar, language control, and menu button wrap without overlap and without horizontal page scrolling

## 3. Focus, skip link, and in-bar controls

- [x] 3.1 Add a `.top-bar :focus-visible` rule using a 3px `var(--md-focus-on-dark)` outline with the existing 3px offset; verify by tabbing through every bar control that the ring is visible against both the gradient and any light-filled control
- [x] 3.2 Repaint `.skip-link` as a light surface with `var(--md-primary)` text; verify it becomes visible on focus at the top inline-start corner and that its boundary is distinguishable from the bar
- [x] 3.3 Give the in-bar language `select` a boundary that reaches at least 3:1 against the gradient (white border or none plus a light fill) while keeping dark text on the light fill; verify the select remains identifiable in both LTR and RTL without relying on the border alone
- [x] 3.4 Add a `forced-colors: active` fallback so the application bar keeps a perceivable boundary (`CanvasText`) when the gradient is replaced; verify with Chromium forced-colors emulation that the bar, focus ring, and current-page indicator remain distinguishable

## 4. Accent usage on light surfaces

- [x] 4.1 Apply `var(--md-accent)` to the notice inline-start border, chip outlines, and section eyebrow text on light surfaces; verify no accent token is applied inside `.top-bar` and that no small accent text falls below 4.5:1
- [x] 4.2 Confirm `--md-accent-soft` is used only for decorative or large-bold labels and never for body-size text or as a background behind body-size text; verify by searching `src/style.css` for every `--md-accent-soft` usage
- [x] 4.3 Confirm destructive controls still use `var(--md-error)` and retain their text labels; verify `.danger-button`, `.danger-text`, `.field-error`, and `.conflict-panel` are untouched

## 5. Metadata and evidence

- [x] 5.1 Update the `theme-color` meta in `index.html` to the mid-gradient value `#5a55c0`; verify by reading the built `index.html` served by the preview
- [x] 5.2 Record the palette, the per-stop white-text ratios, and the manual checks that automated scans cannot cover in `docs/accessibility-and-testing.md`; verify the document names the browser used, the forced-colors result, and any remaining unverified combinations

## 6. Automated contrast guard

- [x] 6.1 Add `tests-js/palette.test.js` that reads `src/style.css`, extracts the palette tokens, and computes WCAG relative luminance and contrast ratios; verify it asserts at least 4.5:1 for white on each of the three top-bar stops, 4.5:1 for `--md-on-top-bar` on each stop, 4.5:1 for `--md-accent` on `--md-surface`, 3:1 for `--md-focus-on-dark` on each stop, and 4.5:1 for `--md-error` on `--md-surface`
- [x] 6.2 Run `node --test tests-js/*.test.js` and confirm the new guard passes alongside the existing JavaScript tests; verify a deliberately lightened stop makes the guard fail before restoring the correct value

## 7. Verification

- [x] 7.1 Run `ELM_HOME=/tmp/commune-elm-home npm run build` and confirm the production build succeeds and the generated CSS contains the new tokens
- [x] 7.2 Run `npm run test:browser` against the dev server and confirm all existing axe WCAG 2.2 AA checks still report zero violations on the routes that render the bar
- [x] 7.3 Manually verify 200% text resize, 400% zoom at 1280 CSS pixels, reduced motion, and forced colors on the feed, a topic, and the compact drawer; confirm the bar never obscures content or focus
- [x] 7.4 Run `openspec validate adopt-blue-purple-header-palette --strict` and confirm the change validates

## 8. Compact navigation correction

- [x] 8.1 Raise the compact media-query selector to `.top-bar nav.desktop-nav` so the desktop navigation is removed below 600 CSS pixels; verify at 320×800 that the navigation computes `display: none` and the bar drops to 130 CSS pixels
- [x] 8.2 Update the width test so 320 pixels asserts navigation appears through the drawer dialog rather than the bar; verify `npm run test:browser` passes
- [x] 8.3 Re-measure focus clearance at 320 and 1280 pixels with 100% and 200% text; verify the focused heading stays below the sticky bar in all four combinations and no horizontal overflow appears

## 9. Header alignment with the page container

- [x] 9.1 Give `.top-bar` inline padding that resolves to the centered page-grid margin, so bar controls share the content container edges; verify at 1920 the brand left edge equals `.page-grid` left (380) and the language select right edge equals `.page-grid` right (1540)
- [x] 9.2 Match the compact page-grid gutter to the bar gutter (both 1rem) so compact widths stay aligned; verify at 320 the language select right edge equals the grid right edge and no horizontal overflow appears
- [x] 9.3 Run the browser suite and production build after the alignment change; verify 39 tests still pass with 1 real-backend skip and axe reports zero violations

## 10. Action-row button alignment

- [x] 10.1 Zero `margin-block-start` for direct children of `.actions`, `.post-actions`, `.dialog-actions`, and `.pagination` so filled, outlined, text, and danger buttons share one top edge; verify measured tops and heights match in all three row types
- [x] 10.2 Confirm stacked contexts keep their spacing (notice text button, error-shell filled button, login-required card) and run the browser suite, JavaScript tests, build, and strict validation

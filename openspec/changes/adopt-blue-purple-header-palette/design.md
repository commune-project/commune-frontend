## Context

See [`proposal.md`](proposal.md) for motivation. Current constraints that shape the approach:

- All colors already flow from a single `:root` token block in [`src/style.css`](../../../src/style.css:1); no Elm module emits color values and no component uses inline styles.
- The top bar and its children are rendered from [`src/App/Shell.elm`](../../../src/App/Shell.elm:61), but styling is entirely class-driven (`.top-bar`, `.brand`, `.desktop-nav`, `.language-control`, `.identity-label`, `.pending-label`, `.compact-menu`, `.link-button`).
- The bar is sticky and currently uses `color-mix(in srgb, var(--md-surface) 94%, transparent)`, so its effective background depends on scrolling content.
- Global `a`, `.link-button`, and `.outlined-button` bind to `--md-primary`; `.identity-label` and `.pending-label` bind to `--md-on-surface-variant`. Both assumptions break on a saturated bar.
- [`index.html`](../../../index.html:7) hardcodes a `theme-color` that already differs from the CSS primary.
- Acceptance already runs axe with WCAG 2.0/2.1/2.2 A/AA tags; axe does not evaluate non-text contrast (1.4.11) or gradient backgrounds reliably.

## Goals / Non-Goals

**Goals:**

- A branded, opaque application bar whose foreground contrast is a fixed, auditable number rather than a function of scroll position.
- One palette source of truth so future theme work edits tokens, not selectors.
- Every foreground, boundary, and focus indicator inside the bar verified against the lightest point of the bar.
- Accent color that reads as an intentional secondary brand color without competing with destructive actions.

**Non-Goals:**

- Board artwork, board logos, thumbnails, or any administrator upload pipeline. Deferred to a future change.
- Background stripe decoration, dark mode, `prefers-color-scheme` variants, typography changes, and any layout or Elm behavior change.
- Introducing a CSS build-time color tool or design-token generator; plain custom properties remain sufficient.

## Decisions

### D1. Gradient stops are bounded by measured luminance, not by visual similarity to the reference

The gradients' lightest stop is the constraint that governs white text. White reaches 4.5:1 only when background relative luminance is at or below `0.1833`. The selected stops are:

| Token | Value | Relative luminance | White contrast |
|---|---|---|---|
| `--md-top-bar-start` | `#4643a3` | 0.0795 | 8.11:1 |
| `--md-top-bar-mid` | `#5a55c0` | 0.1248 | 6.01:1 |
| `--md-top-bar-end` | `#6a63cf` | 0.1615 | 4.89:1 |

Three stops (rather than two) bound intermediate interpolation near the same luminance band and keep the reference's lighter periwinkle feel on the trailing edge. The reference image's lighter periwinkle (`#7e86d8`, 3.34:1) and lightest wash (`#a9b0ea`, ~2.3:1) are rejected as text backgrounds.

Alternative considered: a single flat `#5b5fc7`. Simpler, but loses the reference's depth; the gradient is still a single opaque background so it costs nothing in contrast auditability.

Alternative considered: keep the translucent `color-mix`. Rejected because scroll-dependent contrast cannot be stated as a fixed ratio and cannot be validated by automated scans.

### D2. Foreground is pure white with no alpha

Secondary labels inside the bar must not be dimmed. Compositing white at 90% over `#6a63cf` yields roughly 4.49:1 — below the 4.5:1 threshold by a margin invisible to the eye. Hierarchy inside the bar is expressed by font size and weight only (`--md-on-top-bar: #ffffff`).

### D3. Focus indicator switches inside the bar

The existing `--md-focus: #6b4bd7` reaches only 1.17:1 on the new bar. A second token `--md-focus-on-dark: #ffffff` is applied to `:focus-visible` inside `.top-bar`, keeping 3px width and 3px offset so the ring never sits flush against a white-filled control. The light-surface focus color stays unchanged.

Alternative considered: one dark focus color for both surfaces. Tested `#1c1b20` at 3.44:1 on the bar and 17:1 on light surfaces — passes, but a black ring on a luminous header is visually ambiguous and clashes with forced-colors emulation. Two context-scoped tokens are clearer.

### D4. Current-page state uses structural emphasis plus an indicator

`aria-current="page"` already exists. On the bar, the visible treatment becomes bold weight plus a 3px underline in white (4.89:1 against the lightest stop), so state is not conveyed by hue alone.

### D5. Skip link is repainted because it overlays the bar

The skip link is fixed at the top inline-start corner, directly on the new bar. `--md-primary` on the gradient is only 1.63:1, insufficient for a component boundary. It becomes a light surface with primary text, which yields a 4.96:1 boundary against the bar and keeps 7.7:1 text.

### D6. Accent pink has two tiers, neither used for danger

- `--md-accent: #c2185b` — dual-purpose: 5.54:1 as text on light surfaces and 5.88:1 as a fill behind white text. Used for section eyebrows, chip outlines, and notice borders.
- `--md-accent-soft: #ff4f9a` — large-text-only (3.07:1). Decorative labels at display sizes only; never small text, never a text background at body size.
- Destructive controls keep `--md-error: #ba1a1a` and their explicit text labels. Accent pink is never applied to destructive actions, so the 1.4.1 risk of confusing the two reds is avoided.

### D7. Controls inside the bar keep light fills

The language select keeps a light fill and dark text (contrast of the fill against the bar is 4.89:1). Its border uses `--md-on-top-bar` or is removed; the existing `--md-outline` would be 2.48:1 against the bar and fail 1.4.11.

### D8. Forced colors stays system-driven

Under `forced-colors: active` the browser replaces the gradient and foreground. The only addition is an explicit top-bar boundary fallback (`CanvasText`) so the bar remains a perceivable region, consistent with the existing forced-colors rules for focus and the loading indicator.

## Risks / Trade-offs

- **Automated axe contrast checks cannot reliably sample a gradient background** → Mitigate with explicit per-stop luminance calculations recorded in this design and in the accessibility evidence doc, plus manual keyboard and forced-colors review. Keep stops at three fixed values so the lightest point is enumerable.
- **The trailing stop sits at 4.89:1, a narrow margin** → Mitigate by adding an inline CSS comment stating the ceiling, and by treating any future lightening of `--md-top-bar-end` as a contrast regression requiring recalculation.
- **Gradient interpolation between stops is not guaranteed to stay below the stop luminance for non-sRGB color spaces on wide-gamut displays** → Mitigate by keeping all stops within the same hue family and by testing in Chromium and Firefox; if a browser interpolates in a wider space, the delta is small but the evidence step must sample the rendered pixels rather than trust the declared values.
- **White text on a saturated fill is less comfortable for some low-vision readers than dark text on light** → Mitigate by keeping the bar short, never placing body copy in it, and keeping all bar text at or above the normal-text threshold rather than relying on large-text allowances.
- **Pink accents next to the existing red error state can read as related** → Mitigate by restricting accent use to non-destructive emphasis and retaining explicit text labels on dangerous actions.
- **Any Elm-side class rename would silently detach the styling** → Mitigate by styling only existing class names and by including a browser-level smoke check of the bar's computed background and foreground in the verification tasks.

## Migration Plan

Single-frontend deploy with no data migration. `dist/` and `public/elm.js` are regenerated by the normal build. Rollback is reverting the token block, the top-bar descendant rules, and the `theme-color` value; no persisted state or API contract is involved.

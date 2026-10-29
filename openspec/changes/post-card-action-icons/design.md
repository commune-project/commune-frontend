## Context

See proposal.md for motivation and the delta spec for required behavior.

All four post card actions live in one row in `src/Ui/PostCard.elm` and share the `text-button` class. `Ui.Formatting` already exposes `likesLabel`, `repliesLabel`, and `formattedCount`, so localized count phrases and bare numbers are both available without new translation keys. The stylesheet already provides `.icon-button` as a 48 by 48 circular control and `.sr-only` for visually hidden text; the application bar and drawer use both.

No icon library is present and `elm.json` does not list `elm/svg`. The interface is a Material Design 3 surface that must survive forced colors, 400% zoom, and right-to-left layout. Browser tests locate these controls by role and accessible name, using exact names for edit, delete, and reply, and prefix matches for like and unlike. The delete control carries the identifier that `Main.elm` focuses after the confirmation dialog closes.

## Goals / Non-Goals

**Goals:**

- Replace the four text actions with icon-only controls that keep their current behavior and accessible names.
- Keep like and reply counts visible as localized numbers beside their icons.
- Expose like state through both `aria-pressed` and a filled-versus-outline glyph.
- Keep the change contained to the post card action row, one new icon module, and the stylesheet.

**Non-Goals:**

- Replacing the Unicode glyphs used by the application bar and drawer.
- Introducing an icon font, a CDN reference, or a broader design-system icon set.
- Changing translation keys, backend contracts, or the confirmation dialog.
- Redesigning the rest of the post card.

## Decisions

**Use `elm/svg` and a small local icon module.** Inline SVG keeps the glyphs in `currentColor`, so text contrast rules, dark-on-light surfaces, and forced-colors mode apply without extra rules. A new `src/Ui/Icon.elm` exposes one `Icon` type covering like (filled or outline), edit, delete, and reply, and one `view` function. Each glyph uses a 24 by 24 viewBox, `aria-hidden="true"`, and `focusable="false"`. Alternatives considered: Unicode symbols, which render as color emoji on several platforms and break the single-color treatment; CSS masks, which avoid the dependency but move glyph data into the stylesheet and need a separate forced-colors rule; `Html.node "svg"`, which avoids the dependency at the cost of untyped attribute strings. The requested route is `elm/svg`.

**Build the action row from existing button styles.** Reuse `.icon-button` for the 48 by 48 target and add post-card-specific rules for vertical rhythm and icon size. The edit action stays an anchor so it remains a real link with its existing destination; like, delete, and reply stay native buttons.

**Name controls with `aria-label` instead of hidden visible text.** The like and reply controls now contain a visible number, so wrapping the old full sentence in visually hidden text would duplicate it in the accessible name. An explicit label covers the whole control, keeps the number from being announced without its meaning, and matches the exact names the browser tests already query. The same localized label is applied as a native `title` for pointer users; `aria-label` wins for naming, so the tooltip does not alter test queries.

**Keep the like label composition unchanged.** The accessible name remains the current like or unlike label, a separator, and the full count sentence, so the existing `/^Like/` and `/^Unlike/` queries keep matching. Reply keeps the full count sentence as its name so the exact `1 reply` query keeps matching.

**Show counts as bare localized numbers.** `formattedCount` produces the locale-formatted number without the noun, and the icon supplies the meaning visually. The complete sentence stays in the accessible name.

**Add `aria-pressed` and keep `aria-expanded`.** `boolText` already returns the string form used by the reply toggle, so the like control can expose its state the same way. The glyph switches between a filled and an outline heart, which satisfies the requirement that shape, not color alone, conveys the state.

**Preserve the delete trigger identity.** The button keeps its `delete-post-<id>` identifier and its position in the tab order so focus restoration in `Main.elm` continues to work.

## Risks / Trade-offs

- `elm/svg` must be installed through the Elm package manager, which needs network access. Mitigation: install it as the first implementation step and stop with a clear blocker if the package cannot be fetched, rather than silently switching glyph strategies.
- Icon-only actions are less self-explanatory than words on first use. Mitigation: consistent Material glyphs, a native tooltip, and unchanged assistive names; touch users rely on the glyph and the count.
- `title` and `aria-label` together can cause a duplicated announcement in some screen readers. Mitigation: accept it for now because the tooltip is the only pointer affordance; revisit if manual screen-reader checks report noise.
- A pressed state can diverge from the visual glyph if an optimistic update is rolled back. Mitigation: both derive from the same post value, and existing mutation refresh logic remains the single source of truth.
- Removing the text shortens the row, which changes wrapping at wide viewports. Mitigation: verify the compact and wide layouts in the browser tests and keep the existing flex wrap.

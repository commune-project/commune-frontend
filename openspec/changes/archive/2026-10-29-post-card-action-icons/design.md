## Context

See proposal.md for motivation and the delta spec for required behavior.

All four post card actions live in one row in `src/Ui/PostCard.elm`. An in-progress implementation already renders them as `.icon-button` controls, but the paths in `src/Ui/Icon.elm` are hand-authored; this revision replaces that geometry with data from the official package. `Ui.Formatting` already exposes `likesLabel`, `repliesLabel`, and `formattedCount`, so localized count phrases and bare numbers are both available without new translation keys. The stylesheet already provides `.icon-button` as a 48 by 48 circular control and `.sr-only` for visually hidden text; the application bar and drawer use both.

`elm/svg` is now a direct dependency and the action row has already been converted to icon buttons. Glyph geometry is not hand-authored: the design adopts Google's official `@material-design-icons/svg` package at version 0.14.15. Its `outlined/favorite.svg`, `outlined/favorite_border.svg`, `outlined/edit.svg`, `outlined/delete.svg`, and `outlined/chat_bubble_outline.svg` entries were inspected and each is a single 24 by 24 path with no fill attribute, so the renderer can apply `currentColor` and swap filled for outline on the like control. The interface is a Material Design 3 surface that must survive forced colors, 400% zoom, and right-to-left layout. Browser tests locate these controls by role and accessible name, using exact names for edit, delete, and reply, and prefix matches for like and unlike. The delete control carries the identifier that `Main.elm` focuses after the confirmation dialog closes.

## Goals / Non-Goals

**Goals:**

- Replace the four text actions with icon-only controls that keep their current behavior and accessible names.
- Draw every glyph from the official Material Design icon package instead of hand-authored path data.
- Keep like and reply counts visible as localized numbers beside their icons.
- Expose like state through both `aria-pressed` and a filled-versus-outline glyph.
- Keep the change contained to the post card action row, one icon module, one generated module, a generator script, and the stylesheet.

**Non-Goals:**

- Replacing the Unicode glyphs used by the application bar and drawer.
- Introducing an icon font, a CDN reference, or a broader design-system icon set.
- Changing translation keys, backend contracts, or the confirmation dialog.
- Redesigning the rest of the post card.

## Decisions

**Render official glyphs through `elm/svg`, generated into Elm.** Inline SVG keeps the glyphs in `currentColor`, so text contrast rules, forced-colors mode, and the filled like state work without extra CSS rules. The geometry comes from `@material-design-icons/svg` 0.14.15: `scripts/generate-icons.mjs` extracts the single path from each pinned SVG file and writes `src/Generated/Icons.elm`, following the generated-module pattern already used by `src/Generated/I18n.elm`. `Ui/Icon.elm` keeps one `Icon` type covering like (filled or outline), edit, delete, and reply, and one `view` function with a 24 by 24 viewBox, `aria-hidden="true"`, and `focusable="false"`. The like control renders `favoriteBorder` when unliked and `favorite` when liked, and the renderer applies `fill="currentColor"` to the liked path.

Generating the module instead of pasting paths keeps the data reproducible and turns a package bump into a regeneration step. Alternatives considered: Unicode symbols, which render as color emoji on several platforms and break the single-color treatment; CSS masks, which move glyph data into the stylesheet and need a separate forced-colors rule; loading SVG files at runtime, which adds a request and a loading state to every card; and Material Symbols, whose npm SVG distribution does not pair filled and outline variants the way this pressed-state design needs. The classic Material Design set is used because it ships separate `favorite` and `favorite_border` glyphs.

**Keep the official attribution in the generated file.** The module header records the source package, its pinned version, and the Apache-2.0 license. The generator rewrites the whole file, and the header asks contributors not to edit it by hand.

**Build the action row from existing button styles.** Reuse `.icon-button` for the 48 by 48 target and add post-card-specific rules for vertical rhythm and icon size. The edit action stays an anchor so it remains a real link with its existing destination; like, delete, and reply stay native buttons.

**Name controls with `aria-label` instead of hidden visible text.** The like and reply controls now contain a visible number, so wrapping the old full sentence in visually hidden text would duplicate it in the accessible name. An explicit label covers the whole control, keeps the number from being announced without its meaning, and matches the exact names the browser tests already query. The same localized label is applied as a native `title` for pointer users; `aria-label` wins for naming, so the tooltip does not alter test queries.

**Keep the like label composition unchanged.** The accessible name remains the current like or unlike label, a separator, and the full count sentence, so the existing `/^Like/` and `/^Unlike/` queries keep matching. Reply keeps the full count sentence as its name so the exact `1 reply` query keeps matching.

**Show counts as bare localized numbers.** `formattedCount` produces the locale-formatted number without the noun, and the icon supplies the meaning visually. The complete sentence stays in the accessible name.

**Add `aria-pressed` and keep `aria-expanded`.** `boolText` already returns the string form used by the reply toggle, so the like control can expose its state the same way. The glyph switches between a filled and an outline heart, which satisfies the requirement that shape, not color alone, conveys the state.

**Preserve the delete trigger identity.** The button keeps its `delete-post-<id>` identifier and its position in the tab order so focus restoration in `Main.elm` continues to work.

## Risks / Trade-offs

- Both `elm/svg` and the official icon package need network access to install. Mitigation: `elm/svg` is already installed and the icon package version was verified against the registry, so the remaining npm install is the first implementation step; an offline failure stops with a clear blocker instead of falling back to hand-drawn paths.
- The generated module can drift from the pinned package if someone edits it by hand. Mitigation: the generator rewrites the entire file, the header says not to edit it, and the build regenerates it before compiling.
- Icon-only actions are less self-explanatory than words on first use. Mitigation: consistent Material glyphs, a native tooltip, and unchanged assistive names; touch users rely on the glyph and the count.
- `title` and `aria-label` together can cause a duplicated announcement in some screen readers. Mitigation: accept it for now because the tooltip is the only pointer affordance; revisit if manual screen-reader checks report noise.
- A pressed state can diverge from the visual glyph if an optimistic update is rolled back. Mitigation: both derive from the same post value, and existing mutation refresh logic remains the single source of truth.
- Removing the text shortens the row, which changes wrapping at wide viewports. Mitigation: verify the compact and wide layouts in the browser tests and keep the existing flex wrap.

## Migration Plan

No data migration. Reverting means restoring the text-button action row; the generated module and its generator can be deleted without affecting stored data or API contracts.

## Why

Post card actions currently render as underlined text buttons that consume most of a card's action row and wrap early on compact viewports. Replacing them with Material icon buttons makes the row scannable, keeps the four actions within one line on narrow screens, and aligns the card with the icon controls already used in the application bar and drawer.

## What Changes

- Render the like, edit, delete, and reply-count actions as icon-only controls with a visible count beside like and reply.
- Add a shared icon module that draws the like, edit, delete, and reply glyphs as inline SVG, adding `elm/svg` as a direct dependency.
- Expose every icon as decorative and keep each control's accessible name as the existing localized action label, so assistive technology and browser tests match the current vocabulary.
- Provide the localized action label as a native tooltip for pointer users.
- Show like and reply counts as localized numbers beside their icons while keeping the full localized count sentence in the accessible name.
- Expose like state with `aria-pressed` in addition to the filled/unfilled icon treatment, and keep `aria-expanded` on the reply toggle.
- Preserve the edit link target, the delete confirmation flow, and the delete trigger identifier used to restore focus after the dialog closes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `accessible-material-interface`: adds the presentation and naming rules for icon-only post card actions, including decorative icon handling, 48 by 48 targets, tooltips, count display, and exposed toggle state.

## Impact

- `src/Ui/PostCard.elm`: action row rendering and the count helpers it uses.
- New `src/Ui/Icon.elm`: inline SVG glyphs shared by post card actions.
- `src/style.css`: icon-only action row layout, filled/unfilled like treatment, and icon sizing.
- `elm.json`: `elm/svg` becomes a direct dependency.
- `tests-browser/forum.spec.js` and the accessibility scan: existing role and name queries remain valid; a new assertion covers `aria-pressed`.

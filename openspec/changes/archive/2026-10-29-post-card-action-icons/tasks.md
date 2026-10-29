## 1. Dependencies and official icon source

- [x] 1.1 Add `elm/svg` as a direct dependency with `elm install elm/svg`; verify `elm.json` lists it under direct dependencies and `elm make src/Main.elm --output=/tmp/commune-check.js` succeeds
- [x] 1.2 Add `@material-design-icons/svg` at 0.14.15 as a dev dependency and verify `npm ls @material-design-icons/svg` resolves the pinned version
- [x] 1.3 Add `scripts/generate-icons.mjs` that reads `outlined/favorite`, `outlined/favorite_border`, `outlined/edit`, `outlined/delete`, and `outlined/chat_bubble_outline` from the package and writes `src/Generated/Icons.elm` with one path string per glyph plus a provenance header naming the package, version, and Apache-2.0 license; wire an `icons:generate` script into `package.json` before `dev` and `build`, and verify a second run produces an identical file containing exactly five paths
- [x] 1.4 Rewrite `src/Ui/Icon.elm` to render the generated paths, applying `fill="currentColor"` to the liked heart, and keep the `Icon` type, the 24 by 24 viewBox, `aria-hidden="true"`, and `focusable="false"`; verify `Ui/Icon.elm` contains no authored path data and `elm make src/Main.elm` succeeds

## 2. Post card action row

- [x] 2.1 Replace the four text actions in `src/Ui/PostCard.elm` with icon-only controls, keeping the edit anchor and its `Route.EditPost` destination, the delete button and its `delete-post-<id>` identifier, the like and reply click handlers, and the reply zero-count condition; verify `elm make` succeeds and the existing role-and-name queries in `tests-browser/forum.spec.js` still resolve
- [x] 2.2 Give every action the localized label through `aria-label` plus a matching `title`, keep the icons out of the accessibility tree, and keep the like accessible name in its current like-or-unlike plus count-sentence form; verify a like control and a reply control each expose the full localized phrase while showing only a number
- [x] 2.3 Show like and reply counts as `formattedCount` numbers beside their icons; verify a post with two likes and three replies renders `2` and `3` while the accessible names still contain the localized count sentences
- [x] 2.4 Add `aria-pressed` driven by `post.liked` and switch between the filled and outline heart; verify the toggled state is reported and keep `aria-expanded` on the reply toggle unchanged

## 3. Styles

- [x] 3.1 Style the icon-only action row and glyph size in `src/style.css`, reusing the 48 by 48 `.icon-button` target and removing the row's text-button decoration assumptions; verify the compact card shows four targets on one line at 320 CSS pixels
- [x] 3.2 Verify the filled like glyph and the delete glyph keep at least 3:1 non-text contrast on the card surface, the focus ring stays visible, the disabled like control still reads as disabled, and nothing mirrors under a right-to-left locale
- [x] 3.3 Verify the glyphs inherit `currentColor` in forced-colors mode and add no motion, so the existing reduced-motion rule stays sufficient

## 4. Verification

- [x] 4.1 Run `npm run format:check`, `npm test`, and `npm run build`; verify all three pass with no new warnings and the build regenerates the icon module without leaving a diff
- [x] 4.2 Run `npm run test:browser`; verify the like, delete, edit, reply, and accessibility-scan tests pass, including a new assertion that the like control reports `aria-pressed`
- [x] 4.3 Check `/posts/p1` and the latest feed at 320 CSS pixels, at 400% zoom, and in English, Simplified Chinese, and Traditional Chinese; verify no page-level horizontal scrolling, all four tooltips show the localized label, and the tab order reaches like, edit, delete, reply in that order

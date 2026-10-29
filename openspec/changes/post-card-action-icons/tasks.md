## 1. Dependency and icon module

- [ ] 1.1 Add `elm/svg` as a direct dependency with `elm install elm/svg`; verify `elm.json` lists it under direct dependencies and `elm make src/Main.elm --output=/tmp/commune-check.js` succeeds
- [ ] 1.2 Create `src/Ui/Icon.elm` with one `Icon` type covering filled and outline like, edit, delete, and reply, and one `view` function using a 24 by 24 viewBox with `aria-hidden="true"` and `focusable="false"` on every glyph; verify the module compiles and no glyph includes hard-coded colors

## 2. Post card action row

- [ ] 2.1 Replace the four text actions in `src/Ui/PostCard.elm` with icon-only controls, keeping the edit anchor and its `Route.EditPost` destination, the delete button and its `delete-post-<id>` identifier, the like and reply click handlers, and the reply zero-count condition; verify `elm make` succeeds and the existing role-and-name queries in `tests-browser/forum.spec.js` still resolve
- [ ] 2.2 Give every action the localized label through `aria-label` plus a matching `title`, keep the icons out of the accessibility tree, and keep the like accessible name in its current like-or-unlike plus count-sentence form; verify a like control and a reply control each expose the full localized phrase while showing only a number
- [ ] 2.3 Show like and reply counts as `formattedCount` numbers beside their icons; verify a post with two likes and three replies renders `2` and `3` while the accessible names still contain the localized count sentences
- [ ] 2.4 Add `aria-pressed` driven by `post.liked` and switch between the filled and outline heart; verify the toggled state is reported and keep `aria-expanded` on the reply toggle unchanged

## 3. Styles

- [ ] 3.1 Style the icon-only action row and glyph size in `src/style.css`, reusing the 48 by 48 `.icon-button` target and removing the row's text-button decoration assumptions; verify the compact card shows four targets on one line at 320 CSS pixels
- [ ] 3.2 Verify the filled like glyph and the delete glyph keep at least 3:1 non-text contrast on the card surface, the focus ring stays visible, the disabled like control still reads as disabled, and nothing mirrors under a right-to-left locale
- [ ] 3.3 Verify the glyphs inherit `currentColor` in forced-colors mode and add no motion, so the existing reduced-motion rule stays sufficient

## 4. Verification

- [ ] 4.1 Run `npm run format:check` and `npm test`; verify both pass with no new warnings
- [ ] 4.2 Run `npm run test:browser`; verify the like, delete, edit, reply, and accessibility-scan tests pass, including a new assertion that the like control reports `aria-pressed`
- [ ] 4.3 Check `/posts/p1` and the latest feed at 320 CSS pixels, at 400% zoom, and in English, Simplified Chinese, and Traditional Chinese; verify no page-level horizontal scrolling, all four tooltips show the localized label, and the tab order reaches like, edit, delete, reply in that order

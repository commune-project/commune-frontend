## 1. Contracts and translations

- [ ] 1.1 Add a `Domain.MentionCandidate` record and decoder for `actor_uri`, `acct`, `display_name`, and `avatar`, with empty-string fallbacks; verify with an Elm decoder test.
- [ ] 1.2 Add catalog keys for formatting controls, mention list states, vote group and score labels, and timestamp labels to all three `translations/messages.*.ftl` files; run `npm run i18n:generate` and `npm run i18n:check`.
- [ ] 1.3 Replace the `topic-body-help` text with complete-handle guidance and add profile biography guidance; verify the generated accessors compile and all catalogs pass `npm run i18n:check`.

## 2. Shared Markdown authoring

- [ ] 2.1 Create the shared authoring feature modules for state, update, and view with value, selection, candidate state, and outcome types; verify `ELM_HOME=/tmp/commune-elm-home npm run compile`.
- [ ] 2.2 Add the selection-aware replace-range and focus port commands, including input-event dispatch and caret restoration in `bootstrap.js`; verify with a focused browser check on both editor and profile fields.
- [ ] 2.3 Implement formatting actions for bold, italic, link, inline code, quote, bullet list, and numbered list using the stored selection; verify Elm unit tests cover insertion, wrapping, and unchanged surrounding text.
- [ ] 2.4 Implement active `@` token detection, the 2–64 code point guard, 250 ms debounce, request generations, and stale-response rejection; verify Elm unit tests cover boundary, generation, and error states.
- [ ] 2.5 Render the candidate list with loading, empty, and unavailable states; implement Arrow navigation, Enter/Tab selection, Escape dismissal, pointer selection, combobox/listbox naming, and IME-safe Enter; verify browser tests cover keyboard and composition behavior.
- [ ] 2.6 Insert the complete `@acct` handle with a trailing space and restore the caret; verify browser tests insert local and remote candidates and leave surrounding Markdown intact.
- [ ] 2.7 Integrate the authoring model into topic creation, replies, and post editing while preserving source loading, expected versions, attachments, and conflict panels; verify existing editor browser tests and new authoring tests.
- [ ] 2.8 Integrate the authoring model into profile biography settings and preserve unsent text on rejected saves; verify profile browser tests.
- [ ] 2.9 Confirm candidate failures and empty results do not block submission, and that no WebFinger or client-side handle invention occurs; verify with a mocked failing candidate request.

## 3. Localized timestamps

- [ ] 3.1 Remove the synthetic time sample from `Ports.requestFormatting` and the time fields from `Ui.Formatting`, updating `App.State`, `App.Browser`, and decoders; verify `ELM_HOME=/tmp/commune-elm-home npm run compile`.
- [ ] 3.2 Make the browser bridge format absolute date/time values with the active interface locale and browser time zone, including invalid-date fallback and stable repeated formatting; verify JavaScript tests.
- [ ] 3.3 Replace the dataset-locale guard with a formatted-text comparison and observe child and character mutations under the application root; verify a browser test that changes post metadata and locale without reverting to ISO.
- [ ] 3.4 Convert post cards, notifications, site-admin rows, and account-block rows to semantic `<time datetime data-commune-time>` elements; verify no visible date still uses `formattedDate` and all timestamps format in the browser suite.
- [ ] 3.5 Remove the inline absolute-plus-relative concatenation and verify every visible timestamp contains one localized absolute value and no hour-ago suffix.

## 4. Merged vote control

- [ ] 4.1 Add a presentation component for the upvote button, net score, and downvote button with group naming, selected direction, tooltip breakdown, busy state, and 48 CSS pixel targets; verify Elm tests for permission and selected-state combinations.
- [ ] 4.2 Update post-card callbacks and post mutation handling to submit score `1`, `-1`, or `0` through the vote endpoint, retaining the like endpoint only as an upvote fallback when required; verify mutation unit tests.
- [ ] 4.3 Remove the separate like count, the duplicate downvote label, and the heart-shaped vote action; verify the post-card DOM contains one net score and two direction controls where permitted.
- [ ] 4.4 Add browser tests for the merged score, upvote-to-downvote switching, clearing the selected direction, clearing a disabled existing direction, and busy-state disabling.
- [ ] 4.5 Run the accessibility scan and inspect the vote group with keyboard navigation and an assistive-technology name check; verify selected state and score meaning are exposed without a color-only cue.

## 5. Heading hierarchy

- [ ] 5.1 Add a compact `pageHeading` style and an entity heading variant, remove the global large `h1` clamp, and update post, community-detail, and public-profile pages to use the entity variant; verify `ELM_HOME=/tmp/commune-elm-home npm run compile`.
- [ ] 5.2 Add browser assertions that section headings compute to at most 28 CSS pixels, entity headings compute to at most 36 CSS pixels and remain larger than section headings, and all pages keep one focused `h1`.
- [ ] 5.3 Verify section and entity headings reflow at 320 CSS pixels and 400% zoom without clipping or horizontal scrolling.

## 6. Documentation and acceptance

- [ ] 6.1 Update `docs/architecture.md`, `docs/localization.md`, and `docs/accessibility-and-testing.md` for the shared authoring surface, absolute timestamp ownership, merged vote control, and heading hierarchy; verify links and documented commands.
- [ ] 6.2 Run `npm run format:check`, `npm run i18n:check`, `ELM_HOME=/tmp/commune-elm-home npm run compile`, `ELM_HOME=/tmp/commune-elm-home npm test`, and `npm run test:browser`; record the exact results.
- [ ] 6.3 Run `openspec validate refine-forum-authoring-and-presentation --strict` and confirm every delta requirement and scenario is accepted.
- [ ] 6.4 Attempt the real-backend acceptance with the documented HTTPS proxy and credentials; if unavailable, record the missing prerequisite and the skipped test instead of claiming completion.

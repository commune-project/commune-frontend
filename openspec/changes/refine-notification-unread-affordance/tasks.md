## 1. Notification summary typography

- [ ] 1.1 Add a notification-specific class to the unread-count summary in the notifications action row and a scoped rule that inherits the action row text size, then verify the project still compiles and `npm run format:check` passes
- [ ] 1.2 Add a browser assertion comparing the computed text size of the unread summary with the adjacent read action, and verify the targeted notifications test passes

## 2. Zero unread drawer badge

- [ ] 2.1 Add a zero-count modifier to the drawer notification badge while keeping the count visible and the accessible name complete, and verify the rendered badge still shows `0`
- [ ] 2.2 Style the zero-count modifier with the neutral surface and on-surface-variant tokens while leaving the positive-count error treatment unchanged, and verify both states render with their intended backgrounds
- [ ] 2.3 Add a palette contrast test for the neutral badge text and surface pair, and verify `node --test tests-js/palette.test.js` passes

## 3. Browser coverage and validation

- [ ] 3.1 Parameterize the mocked unread count and add a zero-count browser case that asserts the badge is visible, avoids the error background, and exposes the localized notification phrase with `0`, then verify the targeted Playwright test passes
- [ ] 3.2 Run the project validation commands (`npm run format:check`, `npm run compile`, `npm test`, and `npm run test:browser` against the documented dev server) and verify all checks pass

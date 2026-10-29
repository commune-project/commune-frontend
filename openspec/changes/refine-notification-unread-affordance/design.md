## Context

The notifications page places the bulk-read action and the unread summary in one action row. The read action inherits body text size, while the shared `.chip` rule applies a smaller size used by community mode and policy labels. The drawer renders every available unread count with one error-colored badge rule. See `proposal.md` for the motivating problem and the delta spec for the required behavior.

## Goals / Non-Goals

**Goals:**

- Give the notifications page unread summary the same computed text size as the adjacent read action.
- Keep a zero unread count visible in the drawer with a neutral surface treatment.
- Keep the accessible name complete, including the zero count.
- Limit visual changes to notification affordances.

**Non-Goals:**

- Changing unread-count fetching, persistence, or API behavior.
- Hiding the zero count or changing the badge for positive counts.
- Restyling community mode or policy chips.

## Decisions

### Scope the summary size with a notification-specific modifier

Add a notification-specific class to the unread summary chip and set its text size to inherit from the action row. The shared `.chip` rule remains unchanged because community cards and management surfaces rely on its compact size.

Alternative considered: raise `.chip` globally to body size. Rejected because it would enlarge unrelated metadata chips and exceed the requested scope.

### Distinguish zero with a neutral badge modifier

Keep the existing badge element and shape, but add a zero-state modifier that uses the existing neutral surface and on-surface-variant tokens instead of the error background and white text. The count remains visible, and the positive-count badge keeps its alert treatment.

Alternative considered: hide the badge when the count is zero. Rejected because the selected behavior keeps the zero visible while removing the alert color.

### Preserve the accessible notification phrase

The visible badge remains decorative, and the notification destination keeps an accessible name containing the localized notification phrase and count, including zero. Only its color treatment changes for zero.

### Verify computed behavior in the browser

Extend the existing mocked browser coverage with a zero-count response and assert that the badge is visible, does not use the error background, and keeps the count in its accessible name. On the notifications page, compare the computed text size of the unread summary with the adjacent read action rather than asserting a fixed pixel value.

## Risks / Trade-offs

- **Neutral text contrast on the badge surface** -> Use the existing `--md-on-surface-variant` and `--md-surface-container-high` token pair, which is already used for readable secondary text; verify the rendered contrast in the browser check.
- **The badge may be mistaken for a disabled control at zero** -> Keep the same count text and shape, and verify the accessible name still reports the count; the neutral treatment signals absence of unread alerts without hiding information.
- **Future chip changes could reintroduce the size mismatch** -> Keep the notification modifier adjacent to the shared chip rule and cover the equality with a browser assertion.

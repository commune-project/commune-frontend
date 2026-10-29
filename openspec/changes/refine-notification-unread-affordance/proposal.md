## Why

The notifications page renders its unread-count summary smaller than the adjacent bulk-read action, so the two pieces of the same status row look inconsistent. The navigation drawer also renders a zero unread count with the error-colored badge used for actionable alerts, which makes an empty inbox look like a problem.

## What Changes

- Make the unread-count summary on the notifications page use the same text size as the adjacent read action, scoped to the notifications surface so community mode and policy chips keep their existing compact size.
- Keep the zero unread count visible in the drawer, but render it with a neutral surface treatment instead of the error color.
- Preserve the drawer notification accessible name with the localized phrase and count, including zero.
- Add browser coverage for the zero-count badge treatment and the matching notification action text size.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `accessible-material-interface`: the notification destination badge distinguishes zero unread from unread alerts, and the notifications page presents its unread summary at the same text size as adjacent actions.

## Impact

- `src/Feature/Notifications.elm`: scope the unread-count summary presentation.
- `src/App/Shell.elm`: distinguish the zero-count drawer badge state.
- `src/style.css`: add the scoped summary size and neutral zero-badge treatment.
- `tests-browser/forum.spec.js`: cover zero-count styling and notification action typography.
- No API, dependency, or persisted-data changes.

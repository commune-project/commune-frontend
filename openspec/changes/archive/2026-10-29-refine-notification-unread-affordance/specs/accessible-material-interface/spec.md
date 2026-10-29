## MODIFIED Requirements

### Requirement: Navigation drawer structure

The navigation drawer SHALL be 360 CSS pixels wide where the viewport allows, SHALL begin below the application bar, and SHALL scroll its own content when that content exceeds the viewport height. It SHALL present, in order: a profile header, the primary destinations Latest, Communities, Search, and Notifications, a separator, the account destinations, and a footer containing the language selector and localization status. The drawer SHALL expose a navigation landmark named by the localized main navigation label.

Each destination SHALL render as a control at least 48 CSS pixels tall with a decorative icon and a visible localized label. The current destination SHALL show an indicator surface and at least one non-color cue. The notification destination SHALL display the unread count as a trailing badge, and its accessible name SHALL retain the full localized notification phrase including the count, including when the count is zero. When the unread count is zero, the trailing badge SHALL remain visible with a neutral surface treatment and SHALL NOT use the error color.

#### Scenario: Authenticated destinations

- **WHEN** a signed-in reader opens the drawer
- **THEN** the drawer offers the four primary destinations plus Profile, Settings, and Log out, in that order

#### Scenario: Anonymous destinations

- **WHEN** an anonymous reader opens the drawer
- **THEN** the drawer offers the four primary destinations and a Log in destination, and does not offer Profile, Settings, or Log out

#### Scenario: Unread notification badge

- **WHEN** the signed-in reader has unread notifications
- **THEN** the notification destination shows the count beside its label and its accessible name still contains the complete localized notification phrase

#### Scenario: Zero unread badge

- **WHEN** the signed-in reader has zero unread notifications
- **THEN** the notification destination still shows a zero badge, the badge uses a neutral surface treatment instead of the error color, and its accessible name contains the complete localized notification phrase including the zero count

#### Scenario: Active destination

- **WHEN** the reader is on a destination represented in the drawer
- **THEN** that destination carries a visible indicator and an accessible current-page state that do not depend on color alone

#### Scenario: Narrow drawer width

- **WHEN** the drawer opens on a viewport narrower than 416 CSS pixels
- **THEN** it spans the viewport minus 56 CSS pixels for the dismissing scrim and introduces no page-level horizontal scrolling

## ADDED Requirements

### Requirement: Notification unread summary presentation

On the notifications page, the unread-count summary in the action row SHALL use the same computed text size as the adjacent read action and SHALL render without the accent outline used by categorical chips. These changes SHALL apply to the notification summary only and SHALL NOT change the compact text size or accent outline of community mode or policy chips.

#### Scenario: Unread summary matches the adjacent action

- **WHEN** an authenticated reader views the notifications page with an unread count available
- **THEN** the unread-count summary and the adjacent read action render at the same computed text size, and the unread-count summary has no accent outline

#### Scenario: Community chips keep their compact size

- **WHEN** community mode or policy chips render on community surfaces
- **THEN** their text remains at the existing compact size and their accent outline remains visible

## MODIFIED Requirements

### Requirement: Navigation drawer structure
The navigation drawer SHALL be 360 CSS pixels wide where the viewport allows, SHALL begin below the application bar, and SHALL scroll its own content when that content exceeds the viewport height. It SHALL present, in order: a profile header, the primary destinations Latest, Communities, Search, and Notifications, a separator, any role-gated current-site management destination, the account destinations, and a footer containing the language selector and localization status. The drawer SHALL expose a navigation landmark named by the localized main navigation label.

Each destination SHALL render as a control at least 48 CSS pixels tall with a decorative icon and a visible localized label. The current destination SHALL show an indicator surface and at least one non-color cue. The notification destination SHALL display the unread count as a trailing badge, and its accessible name SHALL retain the full localized notification phrase including the count, including when the count is zero. When the unread count is zero, the trailing badge SHALL remain visible with a neutral surface treatment and SHALL NOT use the error color.

#### Scenario: Authenticated destinations
- **WHEN** a signed-in reader opens the drawer
- **THEN** the drawer offers the four primary destinations plus Profile, My content, Blocks, Settings, and Log out, in that order

#### Scenario: Site administrator destinations
- **WHEN** a signed-in site or deployment administrator opens the drawer
- **THEN** a current-site management destination appears after the primary separator and before account destinations

#### Scenario: Ordinary account destinations
- **WHEN** a signed-in account without administrative roles opens the drawer
- **THEN** no current-site management destination is rendered

#### Scenario: Anonymous destinations
- **WHEN** an anonymous reader opens the drawer
- **THEN** the drawer offers the four primary destinations and a Log in destination, and does not offer Profile, My content, Blocks, Settings, management, or Log out

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

### Requirement: Icon-only post actions
Post cards SHALL present vote, save, personal-hide, edit, delete, report, and reply actions as icon controls or an accessible icon menu rather than ambiguous text buttons. Each control SHALL provide a target of at least 48 by 48 CSS pixels and SHALL expose the localized action label as its accessible name. Action icons SHALL be decorative and hidden from assistive technology. Pointer users SHALL receive the same localized label as a native tooltip.

The upvote and downvote controls SHALL expose their current selected state programmatically and SHALL display visible counts or score where the API provides them. Save and personal-hide controls SHALL expose their current toggle state. The accessible names SHALL retain the complete localized count or state phrase so a visible number is never announced without its meaning.

#### Scenario: Compact action row
- **WHEN** a reader views a post card at a 320 CSS pixel viewport
- **THEN** the action controls remain within the card without page-level horizontal scrolling and do not overlap content

#### Scenario: Accessible action names
- **WHEN** an assistive technology or automated accessibility query inspects a post action
- **THEN** every action is named by its localized purpose, and decorative icons are absent from the accessibility tree

#### Scenario: Counts beside icons
- **WHEN** a post has visible vote, reply, or other count metadata
- **THEN** the corresponding icon displays its localized number and its accessible name still contains the complete localized count sentence

#### Scenario: Like state is exposed
- **WHEN** a reader toggles the compatibility like action and the server accepts the change
- **THEN** the control reports its new pressed state and shows a filled icon when liked and an outline icon when not

#### Scenario: Delete keeps its flow
- **WHEN** a reader activates the delete icon and cancels or confirms the confirmation dialog
- **THEN** the existing confirmation, cancellation, deletion, and focus restoration behavior is unchanged

#### Scenario: Vote state is exposed
- **WHEN** a reader changes an upvote to a downvote
- **THEN** the selected vote direction is exposed programmatically and distinguished by more than color

#### Scenario: Disabled direction
- **WHEN** the site disables a vote direction
- **THEN** the corresponding action is absent or disabled with an accessible explanation and does not appear as an enabled mutation

## ADDED Requirements

### Requirement: Management workspace presentation
Current-site and community management pages SHALL use a clear page heading, labeled sections, native forms, semantic lists, and visible loading, empty, forbidden, conflict, and retry states. Filters and pagination SHALL preserve understandable context. Destructive actions SHALL use explicit localized labels and SHALL not rely on color alone.

#### Scenario: Compact management page
- **WHEN** an administrator uses report, moderation, or ban management at 320 CSS pixels
- **THEN** forms and list content reflow without page-level horizontal scrolling and all actions remain operable

#### Scenario: Unauthorized management state
- **WHEN** a protected management request returns forbidden
- **THEN** the page shows a localized permission message without presenting stale controls as successful

### Requirement: Accessible account and moderation forms
Account block, password reset, password change, report submission, report resolution, and ban forms SHALL provide persistent labels, input guidance, associated errors, and keyboard-operable submission. Confirmation SHALL be required where an action removes access or finalizes a report, and focus SHALL remain predictable after completion or failure. Tokens and passwords SHALL use appropriate input types and SHALL not be exposed in visible text.

#### Scenario: Invalid ban expiry
- **WHEN** an administrator enters an invalid expiry
- **THEN** the localized error is associated with the expiry field and focus remains in the form

#### Scenario: Keyboard report submission
- **WHEN** a keyboard user submits a report without a reason
- **THEN** the error is announced, focus moves to an actionable field or summary, and no request is presented as successful

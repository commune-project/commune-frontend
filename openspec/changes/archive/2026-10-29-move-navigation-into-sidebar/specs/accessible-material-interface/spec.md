## MODIFIED Requirements

### Requirement: Responsive Material presentation

The interface SHALL use consistent Material Design 3 color, typography, elevation, shape, and interaction states. At 1200 CSS pixels and wider, the layout SHALL present a permanent navigation drawer, a bounded discussion column, and contextual information. Below 1200 CSS pixels, the layout SHALL present a single content column whose navigation is available through an accessible modal drawer. Source order SHALL remain meaningful across layouts and directions.

The application bar SHALL present a distinct branded surface that is visually separate from the page surface. It SHALL contain only the menu affordance and the product wordmark, SHALL remain fully opaque, and SHALL stay visible while page content scrolls beneath it. Foreground text, icons, and control boundaries inside the application bar SHALL meet the contrast thresholds in the accessibility conformance requirement against the lightest point of that surface.

Decorative accent color SHALL be confined to emphasis that does not carry meaning alone and SHALL NOT be used for small text on light surfaces unless it meets the text contrast threshold. The current-page state in the navigation drawer SHALL be conveyed by at least one non-color cue in addition to any color change.

#### Scenario: Compact viewport

- **WHEN** a user opens a discussion on a 320 CSS pixel viewport
- **THEN** navigation and actions remain available without page-level horizontal scrolling, except inherently two-dimensional content in its own labeled region

#### Scenario: Branded opaque application bar

- **WHEN** a reader loads any implemented page at any supported viewport
- **THEN** the application bar is visually distinct from the page surface, remains fully opaque and sticky, and its menu affordance and wordmark keep at least a 4.5:1 contrast ratio against the lightest point of its background

#### Scenario: Wide permanent drawer

- **WHEN** a reader loads any implemented page at 1200 CSS pixels or wider
- **THEN** the navigation drawer is visible without interaction and the content column remains bounded without page-level horizontal scrolling

#### Scenario: Header focus and current-page cues

- **WHEN** a keyboard user focuses a control inside the application bar or the navigation drawer
- **THEN** the focus indicator meets at least a 3:1 contrast ratio against its surface, and the current destination is distinguishable through weight or a visible indicator as well as any color change

#### Scenario: Restrained accent on light surfaces

- **WHEN** an accent color is applied to chips, notice borders, or section labels on light surfaces
- **THEN** any small accent text still meets 4.5:1 and no meaning is conveyed by that accent color alone

## ADDED Requirements

### Requirement: Navigation drawer structure

The navigation drawer SHALL be 360 CSS pixels wide where the viewport allows, SHALL begin below the application bar, and SHALL scroll its own content when that content exceeds the viewport height. It SHALL present, in order: a profile header, the primary destinations Latest, Communities, Search, and Notifications, a separator, the account destinations, and a footer containing the language selector and localization status. The drawer SHALL expose a navigation landmark named by the localized main navigation label.

Each destination SHALL render as a control at least 48 CSS pixels tall with a decorative icon and a visible localized label. The current destination SHALL show an indicator surface and at least one non-color cue. The notification destination SHALL display the unread count as a trailing badge, and its accessible name SHALL retain the full localized notification phrase including the count.

#### Scenario: Authenticated destinations

- **WHEN** a signed-in reader opens the drawer
- **THEN** the drawer offers the four primary destinations plus Profile, Settings, and Log out, in that order

#### Scenario: Anonymous destinations

- **WHEN** an anonymous reader opens the drawer
- **THEN** the drawer offers the four primary destinations and a Log in destination, and does not offer Profile, Settings, or Log out

#### Scenario: Unread notification badge

- **WHEN** the signed-in reader has unread notifications
- **THEN** the notification destination shows the count beside its label and its accessible name still contains the complete localized notification phrase

#### Scenario: Active destination

- **WHEN** the reader is on a destination represented in the drawer
- **THEN** that destination carries a visible indicator and an accessible current-page state that do not depend on color alone

#### Scenario: Narrow drawer width

- **WHEN** the drawer opens on a viewport narrower than 416 CSS pixels
- **THEN** it spans the viewport minus 56 CSS pixels for the dismissing scrim and introduces no page-level horizontal scrolling

### Requirement: Drawer profile header

The profile header SHALL occupy the top of the drawer on the opaque brand gradient and SHALL present the signed-in reader's avatar, display name, username, and every administrative role that applies. Avatar images SHALL be decorative and SHALL NOT carry the account name; the visible display name SHALL identify the account. When the profile cannot be loaded, the header SHALL show a non-image placeholder derived from the username and keep the username visible.

Anonymous visitors SHALL see a sign-in destination in place of the profile header and account destinations.

Profile data SHALL survive route changes within an authenticated session and SHALL be cleared when the session ends.

#### Scenario: Signed-in header

- **WHEN** an authenticated reader opens the drawer
- **THEN** the header shows the avatar, display name, username, and localized administrative roles on the brand gradient

#### Scenario: Profile unavailable

- **WHEN** the profile request fails or has not completed
- **THEN** the header replaces the avatar with a textual placeholder and still shows the username without promising account details that are unavailable

#### Scenario: Anonymous header

- **WHEN** an anonymous reader opens the drawer
- **THEN** the header offers a sign-in destination instead of a profile summary

#### Scenario: Header contrast

- **WHEN** the header renders on the brand gradient
- **THEN** its text and icons keep at least 4.5:1 against the lightest gradient stop, and the avatar boundary reaches at least 3:1

#### Scenario: Route change keeps the header

- **WHEN** an authenticated reader navigates between two pages
- **THEN** the drawer header keeps the loaded profile instead of falling back to a placeholder or issuing a new request for every route

### Requirement: Drawer modes and menu affordance

At 1200 CSS pixels and wider the drawer SHALL be permanent, and the application bar menu button SHALL collapse and expand it without navigating. Below 1200 CSS pixels the menu button SHALL open the drawer as a modal dialog. The modal drawer SHALL close on Escape or on destination activation and SHALL restore focus to the menu button.

The collapsed or expanded choice SHALL NOT persist across reloads; each load SHALL start with the permanent drawer expanded and the modal drawer closed. Crossing the 1200 CSS pixel boundary SHALL resolve the drawer into the mode matching the new viewport without leaving a modal open over a permanent layout.

#### Scenario: Collapse on a wide viewport

- **WHEN** a reader activates the menu button at 1200 CSS pixels or wider
- **THEN** the permanent drawer is removed from view, the content column expands, and the menu button reports the collapsed state

#### Scenario: Open on a narrow viewport

- **WHEN** a reader activates the menu button below 1200 CSS pixels
- **THEN** the drawer opens as a named modal dialog over a scrim and focus moves inside it

#### Scenario: Escape restores focus

- **WHEN** a keyboard reader presses Escape in the modal drawer
- **THEN** the drawer closes and focus returns to the menu button

#### Scenario: Reload defaults

- **WHEN** an authenticated reader reloads a wide page after collapsing the drawer
- **THEN** the drawer loads expanded because the choice is not persisted

#### Scenario: Breakpoint crossing

- **WHEN** the viewport crosses 1200 CSS pixels while the modal drawer is open
- **THEN** the drawer resolves into the mode of the new viewport without trapping focus or leaving a modal over the permanent layout

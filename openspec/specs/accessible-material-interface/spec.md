# accessible-material-interface Specification

## Purpose
Provide a responsive Material Design forum that supports keyboard, assistive technology, low vision, touch, and diverse text presentation needs throughout its workflows.

## Requirements

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

### Requirement: Accessibility conformance
All shipped workflows in all three locales SHALL meet applicable WCAG 2.2 Level A and AA criteria. Text contrast SHALL be at least 4.5:1 for ordinary text and 3:1 for large text; essential non-text indicators SHALL meet 3:1. The interface SHALL support 200% text resize, 400% zoom/reflow, text-spacing overrides, forced colors, and reduced motion. Controls SHALL target 48 by 48 CSS pixels where practical and meet WCAG 2.2 target-size requirements in all cases.

#### Scenario: Zoom and text spacing
- **WHEN** a reader applies 400% zoom at a 1280 CSS pixel viewport or WCAG text-spacing overrides
- **THEN** content and actions remain readable and operable without clipping, loss, or overlapping fixed controls

### Requirement: Semantic navigation and keyboard operation
Pages SHALL expose landmarks, one primary heading, meaningful heading hierarchy, a skip link, labeled native controls, and descriptive link/button names. Every action SHALL be keyboard operable with visible, unobscured focus and logical tab order. SPA navigation SHALL update the title and move focus to the new page heading; pagination and reply expansion SHALL keep focus predictable without resetting the whole page.

#### Scenario: Navigate by keyboard
- **WHEN** a keyboard user follows a topic link and then expands replies
- **THEN** the destination heading receives focus and expansion keeps focus on its trigger with its expanded state exposed

### Requirement: Accessible dialogs and feedback
Modal dialogs and drawers SHALL expose their names and roles, contain focus while modal, prevent background interaction, support Escape dismissal, and restore focus to the trigger or a meaningful surviving alternative. Loading, mutation completion, errors, unread counts, and upload progress SHALL have localized programmatic feedback without excessive live announcements. Color alone SHALL not convey meaning.

#### Scenario: Cancel deletion
- **WHEN** a keyboard or screen-reader user opens and cancels a delete confirmation
- **THEN** the dialog is named, focus stays inside until dismissal, no deletion occurs, and focus returns to the originating action

### Requirement: Accessible forms authentication and content
Forms SHALL provide persistent labels, instructions, associated field errors, and an actionable error summary where multiple errors exist. Authentication SHALL allow password managers and paste and SHALL not impose cognitive puzzles. Uploads SHALL offer a native file chooser without requiring drag gestures. Author-supplied image descriptions SHALL be preserved, decorative icons hidden from assistive technology, and informative attachments given meaningful accessible names.

#### Scenario: Invalid login submission
- **WHEN** login fails or required input is missing
- **THEN** localized feedback is announced and associated with the relevant controls without clearing the login identifier or blocking password-manager interaction

### Requirement: Evidence-based accessibility verification
Acceptance SHALL include automated accessibility scans and manual keyboard and screen-reader checks of representative complete workflows in every locale, plus mixed-direction and complex-script fixtures. Findings SHALL document tested browser/assistive-technology combinations and unresolved failures; automated scans alone SHALL not be described as full conformance.

#### Scenario: Release verification
- **WHEN** the initial frontend is prepared for acceptance
- **THEN** its English report records automated results, manual keyboard and screen-reader outcomes, locale/RTL/IME coverage, and any remaining conformance blockers

### Requirement: Icon-only post actions
Post cards SHALL present the merged vote control, save, personal-hide, edit, delete, report, and reply actions as icon controls or an accessible icon menu rather than ambiguous text buttons. Each control SHALL provide a target of at least 48 by 48 CSS pixels and SHALL expose the localized action label as its accessible name. Action icons SHALL be decorative and hidden from assistive technology. Pointer users SHALL receive the same localized label as a native tooltip.

The merged vote control SHALL display one net score between an upvote control and a downvote control. Each direction SHALL expose its current selected state programmatically and SHALL be distinguished by more than color. The accessible names SHALL include the direction and the complete localized score or count phrase so a visible number is never announced without its meaning. The compatibility like action SHALL be presented as the upvote direction and SHALL NOT create a separate visible score or toggle.

Save and personal-hide controls SHALL expose their current toggle state. The reply control SHALL continue to expose its expanded state.

#### Scenario: Compact action row
- **WHEN** a reader views a post card at a 320 CSS pixel viewport
- **THEN** the action controls remain within the card without page-level horizontal scrolling and do not overlap content

#### Scenario: Accessible action names
- **WHEN** an assistive technology or an automated accessibility query inspects a post card action
- **THEN** every action is named by its localized purpose, and decorative icons are absent from the accessibility tree

#### Scenario: Counts beside icons
- **WHEN** a post has a visible vote net score or reply count
- **THEN** the corresponding control displays its localized number and its accessible name still contains the complete localized count sentence

#### Scenario: Merged vote group
- **WHEN** a post has multiple upvotes and downvotes
- **THEN** the card presents one net score between the upvote and downvote controls and does not present a separate like count

#### Scenario: Upvote state is exposed
- **WHEN** a reader toggles the upvote direction and the server accepts the change
- **THEN** the upvote control reports its new pressed state and the visible net score updates from authoritative post metadata

#### Scenario: Like state is exposed
- **WHEN** a reader toggles the compatibility like action and the server accepts the change
- **THEN** the upvote direction reports the new pressed state, uses a filled icon for the selected state, and does not add a separate like score

#### Scenario: Delete keeps its flow
- **WHEN** a reader activates the delete icon and cancels or confirms the confirmation dialog
- **THEN** the existing confirmation, cancellation, deletion, and focus restoration behavior is unchanged

#### Scenario: Vote state is exposed
- **WHEN** a reader changes an upvote to a downvote
- **THEN** the selected vote direction is exposed programmatically and distinguished by more than color

#### Scenario: Disabled direction
- **WHEN** the site disables a vote direction
- **THEN** the corresponding action is absent or disabled with an accessible explanation and does not appear as an enabled mutation

### Requirement: Page heading hierarchy
Section pages SHALL use a compact primary heading for destinations such as latest discussions, communities, search, notifications, settings, and authoring. The computed font size of a section heading SHALL NOT exceed 28 CSS pixels at any supported viewport. Entity pages for a post, community, or profile detail MAY use a primary heading of up to 36 CSS pixels and SHALL remain visually distinct from section headings. Every page SHALL retain exactly one primary heading, preserve heading focus after navigation, and reflow without clipping at 320 CSS pixels, 200% text resize, and 400% zoom.

#### Scenario: Section headings stay compact
- **WHEN** a reader opens latest discussions, communities, search, notifications, settings, or an authoring page
- **THEN** the primary heading renders at no more than 28 CSS pixels and remains subordinate to the page content

#### Scenario: Entity headings remain distinct
- **WHEN** a reader opens a post, community, or profile detail page
- **THEN** the primary heading remains larger than a section heading and does not exceed 36 CSS pixels

#### Scenario: Compact viewport and zoom
- **WHEN** a reader opens a section page at 320 CSS pixels or at 400% zoom
- **THEN** the heading wraps without clipping and the page introduces no horizontal scrolling

#### Scenario: Navigation focus is preserved
- **WHEN** SPA navigation moves focus to the destination heading
- **THEN** the heading remains the single primary heading and receives focus with the compact or entity treatment appropriate to the page

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

### Requirement: Notification unread summary presentation
On the notifications page, the unread-count summary in the action row SHALL use the same computed text size as the adjacent read action and SHALL render without the accent outline used by categorical chips. These changes SHALL apply to the notification summary only and SHALL NOT change the compact text size or accent outline of community mode or policy chips.

#### Scenario: Unread summary matches the adjacent action
- **WHEN** an authenticated reader views the notifications page with an unread count available
- **THEN** the unread-count summary and the adjacent read action render at the same computed text size, and the unread-count summary has no accent outline

#### Scenario: Community chips keep their compact size
- **WHEN** community mode or policy chips render on community surfaces
- **THEN** their text remains at the existing compact size and their accent outline remains visible

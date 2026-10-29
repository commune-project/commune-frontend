# accessible-material-interface Specification

## Purpose
Provide a responsive Material Design forum that supports keyboard, assistive technology, low vision, touch, and diverse text presentation needs throughout its workflows.

## Requirements

### Requirement: Responsive Material presentation

The interface SHALL use consistent Material Design 3 color, typography, elevation, shape, and interaction states. Wide layouts SHALL provide navigation, a bounded discussion column, and contextual information; compact layouts SHALL use accessible drawer navigation and a single content column. Source order SHALL remain meaningful across layouts and directions.

The application bar SHALL present a distinct branded surface that is visually separate from the page surface. Its background SHALL be fully opaque so the effective contrast of its contents does not change while page content scrolls beneath it. Foreground text, icons, and control boundaries inside the application bar SHALL meet the contrast thresholds in the accessibility conformance requirement against the lightest point of that surface.

Decorative accent color SHALL be confined to emphasis that does not carry meaning alone and SHALL NOT be used for small text on light surfaces unless it meets the text contrast threshold. The current-page state in the application bar SHALL be conveyed by at least one non-color cue in addition to any color change.

#### Scenario: Compact viewport

- **WHEN** a user opens a discussion on a 320 CSS pixel viewport
- **THEN** navigation and actions remain available without page-level horizontal scrolling, except inherently two-dimensional content in its own labeled region

#### Scenario: Branded opaque application bar

- **WHEN** a reader loads any implemented page at any supported viewport
- **THEN** the application bar is visually distinct from the page surface, remains fully opaque and sticky, and all of its text and icons keep at least a 4.5:1 contrast ratio against the lightest point of its background

#### Scenario: Header focus and current-page cues

- **WHEN** a keyboard user focuses a control inside the application bar or reads the navigation of the current page
- **THEN** the focus indicator meets at least a 3:1 contrast ratio against the bar, and the current page is distinguishable through weight or a visible indicator as well as any color change

#### Scenario: Restrained accent on light surfaces

- **WHEN** an accent color is applied to chips, notice borders, or section labels on light surfaces
- **THEN** any small accent text still meets 4.5:1 and no meaning is conveyed by that accent color alone

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
Post cards SHALL present their like, edit, delete, and reply actions as icon-only controls rather than text links. Each control SHALL provide a target of at least 48 by 48 CSS pixels and SHALL expose the localized action label as its accessible name. Action icons SHALL be decorative and hidden from assistive technology. Pointer users SHALL receive the same localized label as a native tooltip.

The like and reply controls SHALL display their localized count as a visible number next to the icon. The accessible name SHALL retain the complete localized count phrase so the number is never announced without its meaning.

The like control SHALL expose its current state programmatically as a pressed toggle and SHALL distinguish the liked state through icon shape as well as color. The reply control SHALL continue to expose its expanded state.

#### Scenario: Compact action row
- **WHEN** a reader views a post card at a 320 CSS pixel viewport
- **THEN** the four actions render as icon controls and remain within the card without page-level horizontal scrolling

#### Scenario: Accessible action names
- **WHEN** an assistive technology or an automated accessibility query inspects a post card action
- **THEN** the like control is named by the localized like or unlike label, the edit control by the localized edit label, the delete control by the localized delete label, and the reply control by the full localized reply count phrase, while the icon itself is absent from the accessibility tree

#### Scenario: Counts beside icons
- **WHEN** a post has two likes and three direct replies
- **THEN** the like and reply icons each display their localized number, and their accessible names still contain the complete localized count sentences

#### Scenario: Like state is exposed
- **WHEN** a reader toggles the like action and the server accepts the change
- **THEN** the control reports its new pressed state and shows a filled icon when liked and an outline icon when not liked

#### Scenario: Delete keeps its flow
- **WHEN** a reader activates the delete icon and cancels or confirms the confirmation dialog
- **THEN** the existing confirmation, cancellation, deletion, and focus restoration behavior is unchanged

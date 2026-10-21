# accessible-material-interface Specification

## Purpose
Provide a responsive Material Design forum that supports keyboard, assistive technology, low vision, touch, and diverse text presentation needs throughout its workflows.

## Requirements

### Requirement: Responsive Material presentation
The interface SHALL use consistent Material Design 3 color, typography, elevation, shape, and interaction states. Wide layouts SHALL provide navigation, a bounded discussion column, and contextual information; compact layouts SHALL use accessible drawer navigation and a single content column. Source order SHALL remain meaningful across layouts and directions.

#### Scenario: Compact viewport
- **WHEN** a user opens a discussion on a 320 CSS pixel viewport
- **THEN** navigation and actions remain available without page-level horizontal scrolling, except inherently two-dimensional content in its own labeled region

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

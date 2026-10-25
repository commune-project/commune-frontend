## MODIFIED Requirements

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

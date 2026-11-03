## MODIFIED Requirements

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

## ADDED Requirements

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

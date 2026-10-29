## ADDED Requirements

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

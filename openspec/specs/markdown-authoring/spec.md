# markdown-authoring Specification

## Purpose

Give readers one consistent, source-first Markdown authoring surface for discussions and profile biographies, with formatting controls and reliable actor mentions.

## Requirements

### Requirement: Shared Markdown authoring surface
The application SHALL provide a source-first Markdown editor for topic creation, replies, post editing, and profile biography editing. The editor SHALL preserve the stored Markdown source, load existing values from the source APIs rather than reconstructing them from rendered HTML, and submit only the user-edited source. The editor SHALL provide visible controls for bold, italic, link, inline code, quote, bullet list, and numbered list. Formatting actions SHALL apply to the current selection, preserve focus and the surrounding text, and work with keyboard and pointer input. The editor SHALL NOT use contenteditable rendering or inject editor source as trusted HTML.

#### Scenario: Topic and reply authoring stay consistent
- **WHEN** an authenticated reader composes a topic or reply
- **THEN** the same Markdown authoring surface is presented, the submitted body remains Markdown source, and no rendered HTML is sent in place of the source

#### Scenario: Profile biography uses Markdown authoring
- **WHEN** an authenticated reader opens profile settings
- **THEN** the biography field uses the shared Markdown authoring surface and saves the edited Markdown source through the profile endpoint

#### Scenario: Formatting applies to the selection
- **WHEN** a reader selects text and activates a formatting control
- **THEN** only the selected range is wrapped or prefixed, the remaining text is unchanged, and focus returns to the editor

#### Scenario: Legacy source remains legacy
- **WHEN** a reader edits a post whose stored content format is not Markdown
- **THEN** the editor preserves the legacy format unless the reader explicitly changes it

### Requirement: Mention candidate lookup
While an authenticated reader is editing a post or biography, the application SHALL offer mention candidates after an `@` token reaches two and at most sixty-four Unicode code points. The application SHALL request at most eight candidates from `GET /api/v1/mentions/candidates`, SHALL debounce repeated input, and SHALL ignore responses that no longer match the active token. It SHALL present loading, empty, and unavailable states without blocking text entry or submission. The candidate response SHALL be treated as display data only; the application SHALL NOT invent handles, perform WebFinger or Actor discovery, or imply that a candidate is a current community member.

#### Scenario: Query after two characters
- **WHEN** a reader types `@al` in an authoring field
- **THEN** the application requests candidates for `al` and presents matching local and known remote accounts

#### Scenario: One character does not query
- **WHEN** a reader has typed only `@a`
- **THEN** no candidate request is issued and the editor remains usable

#### Scenario: Stale response is ignored
- **WHEN** a candidate response arrives after the active mention token has changed
- **THEN** the stale items are not displayed and the current token state remains unchanged

#### Scenario: Candidate lookup is unavailable
- **WHEN** the candidate request fails or returns an error
- **THEN** the editor reports a localized non-blocking state, preserves the source text, and still permits submission

### Requirement: Mention insertion and keyboard operation
Selecting a candidate SHALL replace the active `@` token with `@` followed by the full `acct` returned by the endpoint, followed by a separating space, and SHALL place the caret after the inserted handle. The candidate list SHALL support pointer selection, Arrow Up and Arrow Down movement, Enter or Tab confirmation, and Escape dismissal. Enter during IME composition SHALL NOT confirm a candidate or submit the form. The list SHALL expose combobox and listbox semantics, keep focus in the text area, name each option with its display name and handle, and provide localized status for loading, empty, and selected states.

#### Scenario: Insert a local handle
- **WHEN** a reader selects a local candidate with `acct` `alice@forum.example`
- **THEN** the active token becomes `@alice@forum.example ` and the caret follows the inserted space

#### Scenario: Insert a remote handle
- **WHEN** a reader selects a stored remote candidate
- **THEN** the complete returned handle is inserted without client-side domain inference

#### Scenario: Keyboard navigation
- **WHEN** the candidate list is open and the reader presses Arrow Down, Enter, or Escape
- **THEN** the active option changes, the selected option is inserted, or the list closes while focus remains in the editor

#### Scenario: IME composition is preserved
- **WHEN** the reader is confirming an IME composition with Enter while the candidate list is open
- **THEN** the composed text is retained and neither a candidate nor the form is submitted

### Requirement: Authoring accessibility and resilience
Authoring fields SHALL retain persistent labels and instructions, associate localized errors with the field, and preserve unsent text when uploads, candidate lookup, or submission fail. Formatting and candidate controls SHALL have localized accessible names and targets of at least 48 by 48 CSS pixels. The authoring surface SHALL reflow at 320 CSS pixels and remain operable at 200% text resize and 400% zoom without page-level horizontal scrolling.

#### Scenario: Mobile authoring
- **WHEN** a reader opens a topic editor at a 320 CSS pixel viewport
- **THEN** the editor, toolbar, candidate list, and submit action remain operable without page-level horizontal scrolling

#### Scenario: Submission failure preserves the draft
- **WHEN** a post save fails after the reader has edited the source
- **THEN** the source, title, format, and existing attachment selections remain in the editor

#### Scenario: Screen-reader naming
- **WHEN** an assistive technology inspects the authoring surface
- **THEN** the body field, each formatting control, and each candidate option expose localized names without announcing decorative icons

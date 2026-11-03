## MODIFIED Requirements

### Requirement: Localized formatting and messages
The application SHALL format numbers, absolute dates and times, and plurals using locale-aware complete messages rather than concatenated fragments. Time displays SHALL use the browser's time zone and the active interface locale, SHALL expose the absolute timestamp through semantic time metadata, and SHALL NOT display the raw ISO source after hydration or after an Elm re-render. Visible timestamp text SHALL NOT append a separately concatenated relative-time phrase. Catalog validation SHALL reject missing keys or incompatible parameters. Browser locale normalization failures SHALL not crash rendering.

#### Scenario: Time and count labels
- **WHEN** a reader changes locale while viewing a discussion
- **THEN** count labels and timestamps are reformatted without changing stored timestamps, identifiers, or API payload semantics

#### Scenario: Re-render keeps localized time
- **WHEN** a post interaction refreshes visible metadata for an existing timestamp
- **THEN** the timestamp remains in the localized absolute form and does not revert to its ISO source text

#### Scenario: Invalid timestamp remains safe
- **WHEN** a timestamp cannot be parsed by the browser
- **THEN** the interface displays the original source text unchanged and does not invent a date or time

#### Scenario: No mixed absolute and relative timestamp
- **WHEN** a timestamp is visible in a list or post card
- **THEN** it contains one localized absolute date and time value and does not append a relative phrase such as an hour-ago label

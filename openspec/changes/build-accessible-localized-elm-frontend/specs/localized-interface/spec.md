## Purpose

Make every forum workflow usable in the three initial locales and establish reliable behavior for bidirectional content, complex scripts, and future translations.

## ADDED Requirements

### Requirement: Complete initial locale support
The interface SHALL ship complete, independently reviewed catalogs for `en-US`, `zh-cmn-Hans-CN`, and `zh-cmn-Hant-TW`. Visible strings, page titles, accessible names, validation, empty/error states, notifications, and dynamic announcements SHALL use the selected locale. User content and actor identities SHALL not be translated. Simplified and Traditional Chinese SHALL be separate translations rather than automatic character conversion.

#### Scenario: Switch script variant
- **WHEN** a user changes from Simplified Chinese to Traditional Chinese
- **THEN** all interface messages and accessible labels change to the Traditional Chinese catalog while content, URL context, and unsent form text remain intact

### Requirement: Locale negotiation and persistence
An explicit saved selection SHALL take precedence over browser language preferences, with `en-US` as the final fallback. The application SHALL accept the requested Chinese identifiers and common equivalent `zh`/`cmn` script-region aliases, favor an explicit script over a conflicting region, and deterministically map bare Chinese to the Simplified catalog. The language chooser SHALL use native language names, be available before login, and work when browser storage is unavailable. Document language SHALL follow the active locale.

#### Scenario: Traditional Chinese browser preference
- **WHEN** no selection is saved and the browser requests `zh-TW`, `zh-Hant`, or `cmn-Hant-TW`
- **THEN** the selected catalog is `zh-cmn-Hant-TW`

#### Scenario: Unsupported language
- **WHEN** none of the browser's ordered preferences matches a supported locale
- **THEN** the interface uses `en-US` and keeps the language chooser available

### Requirement: Localized formatting and messages
The application SHALL format numbers, dates, relative times, and plurals using locale-aware complete messages rather than concatenated fragments. Time displays SHALL use the browser's time zone and expose an absolute timestamp. Catalog validation SHALL reject missing keys or incompatible parameters. Browser locale normalization failures SHALL not crash rendering.

#### Scenario: Time and count labels
- **WHEN** a reader changes locale while viewing a discussion
- **THEN** count labels and timestamps are reformatted without changing stored timestamps, identifiers, or API payload semantics

### Requirement: Bidirectional layout and content
The interface SHALL support direction metadata for future RTL catalogs and verify the shared components in an RTL test configuration. User text SHALL determine its own direction; actor identifiers and mixed-direction fragments SHALL be isolated. Layout SHALL use logical start/end behavior and mirror directional navigation icons without reversing logos, media, code, or meaningful text. Initial production catalogs SHALL remain LTR.

#### Scenario: Arabic content within a Chinese interface
- **WHEN** an Arabic reply includes an actor URI, Latin code, and numeric timestamp
- **THEN** the reply direction and isolated fragments remain readable without changing the surrounding interface direction

### Requirement: Complex script input and typography
Text controls SHALL preserve composition events and Unicode text, avoid submitting or triggering shortcuts during IME composition, and support shaping, combining marks, emoji sequences, CJK wrapping, and locale-appropriate font fallbacks. Text SHALL not be split or truncated inside grapheme clusters. Layout SHALL accommodate expanded translations and variable glyph metrics without clipped controls.

#### Scenario: Confirming IME composition
- **WHEN** a user presses Enter to confirm a Chinese input candidate
- **THEN** the composed text is retained and the form is not prematurely submitted

#### Scenario: Complex script rendering
- **WHEN** a discussion contains Arabic, Devanagari, Thai, combining accents, and joined emoji
- **THEN** text remains shaped, selectable, and readable without broken clusters or forced Latin spacing

### Requirement: English engineering text
Source comments and authored project documentation, including OpenSpec artifacts, SHALL use English. Translation values, language names, test fixtures representing multilingual content, and user content SHALL retain their required languages.

#### Scenario: Adding a localized component
- **WHEN** an engineer adds component documentation and Chinese translation messages
- **THEN** documentation and comments are English and the translation messages remain Chinese

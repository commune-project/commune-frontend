# dynamic-localization-resources Specification

## Purpose
Deliver complete, type-safe interface translations as on-demand resources that can switch languages safely while preserving user work and accessible behavior.

## Requirements

### Requirement: Generated dynamic catalogs
The application SHALL generate type-safe accessors from translator-owned Fluent catalogs for `en-US`, `zh-cmn-Hans-CN`, and `zh-cmn-Hant-TW`. Each production build SHALL include complete catalogs for all three locales with matching message identities and parameter signatures. Translation JSON SHALL be loaded dynamically from the application's same-origin static assets; the initial JavaScript bundle SHALL NOT embed all catalogs.

#### Scenario: Missing translation detected
- **WHEN** a locale omits a required message or uses an incompatible placeholder signature
- **THEN** the build fails with the locale and message identified, and no incomplete production bundle is emitted

#### Scenario: Alternate language is loaded
- **WHEN** a reader selects a language whose catalog is not currently loaded
- **THEN** the application requests that locale's generated JSON from the same origin and does not download every supported catalog up front

### Requirement: Initial catalog selection and fallback
Before presenting normal application content, the application SHALL resolve the public locale from the saved explicit choice or ordered browser preferences and load its catalog. If that request fails, it SHALL attempt the `en-US` catalog and expose an accessible notice that English was substituted. If every catalog load fails, it SHALL present an accessible retry state and retain the language chooser.

#### Scenario: Selected catalog is unavailable
- **WHEN** the initial Traditional Chinese catalog cannot be loaded but English can
- **THEN** the interface becomes operable in English, identifies the substitution, and offers another attempt at Traditional Chinese

#### Scenario: All catalogs are unavailable
- **WHEN** initial catalog requests fail for all supported locales
- **THEN** the application remains operable enough to retry and change language without displaying untranslated application content as if loading had succeeded

### Requirement: Atomic and race-safe language switching
A language change SHALL take effect only after its catalog has loaded successfully. The current catalog and interface SHALL remain usable while a new catalog loads. Requests SHALL be correlated with locale and an increasing switch identity so responses from superseded choices are ignored. A successful switch SHALL preserve route state, unsent form values, scroll context where practical, and current focus, then update document language and direction consistently.

#### Scenario: Rapid language choices
- **WHEN** a reader requests Simplified Chinese and then Traditional Chinese before the first request completes
- **THEN** only the final selected catalog may replace the interface and the earlier response is discarded

#### Scenario: Switch preserves draft
- **WHEN** a reader changes language while an unsaved post contains text
- **THEN** the post remains in the editor with the same text and logical focus

### Requirement: Switching failure and recovery
If an on-demand switch fails, the application SHALL retain the previously loaded catalog and identify the failed target language without claiming success. It SHALL provide a localized retry action and keep a language chooser available. Failed, malformed, unsupported-version, and cross-origin catalog responses SHALL not partially apply messages or execute content.

#### Scenario: Invalid catalog response
- **WHEN** a catalog request returns malformed JSON or a response incompatible with the generated accessors
- **THEN** the active language remains unchanged and accessible recovery feedback is announced

### Requirement: Build identity and release-safe caching
Generated catalog assets and the Elm accessors that decode them SHALL be built and deployed as one release. Catalog URLs SHALL include a build identity suitable for immutable caching. A deployment SHALL retain hashed assets required by clients from preceding supported releases until those clients can no longer remain active, while deployment fallback SHALL not answer missing catalog URLs with HTML.

#### Scenario: Updated translation release
- **WHEN** a new release changes a message identity or catalog contents
- **THEN** clients receive matching accessors and assets without interpreting an older catalog with newer generated expectations

#### Scenario: Missing hashed catalog
- **WHEN** a hashed catalog URL is no longer available
- **THEN** the server returns a clear not-found response rather than the SPA shell and the client reports a localized load failure

### Requirement: Locale-specific presentation remains intact
Locale-aware numbers, dates, relative times, plurals, accessible names, live feedback, and language names SHALL use the same active catalog and browser Intl behavior. Interface catalogs SHALL remain writable in Simplified and Traditional Chinese independently. User content, identifiers, bidirectional text isolation, complex-script rendering, IME behavior, and RTL testing SHALL continue to satisfy the existing localization and accessibility requirements.

#### Scenario: Language changes around bilingual content
- **WHEN** a reader changes the interface among the three locales while viewing mixed-direction user text
- **THEN** interface messages and formatting change atomically while user content remains unchanged and isolated

### Requirement: No runtime translation service dependency
The production application SHALL load translation resources from the Commune deployment and use browser facilities for formatting. It SHALL not require a third-party translation service, remote CDN, API key, authentication token, or network request to a translation provider at runtime.

#### Scenario: Translation provider is unreachable
- **WHEN** an external translation vendor is unavailable but Commune's own static assets are healthy
- **THEN** all supported interface language loading and switching continue to work

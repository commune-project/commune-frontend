## Why

Commune has browser-facing forum APIs but no frontend application. An Elm frontend will make those capabilities usable through a responsive Material Design interface with localization and accessibility built into its foundations.

## What Changes

- Build an Elm single-page application for discovery, discussions, authentication and verified registration, profiles, search, notifications, Markdown attachments, and community management using existing backend endpoints.
- Introduce a responsive Material Design 3 component system with semantic HTML, keyboard navigation, and WCAG 2.2 Level AA acceptance criteria.
- Ship complete UI catalogs for `en-US`, `zh-cmn-Hans-CN`, and `zh-cmn-Hant-TW`, including accessible names, validation, statuses, and localized formatting.
- Support bidirectional user content and prepare layouts, typography, and input handling for RTL and complex scripts; an additional RTL UI translation is outside the first release.
- Keep source comments and project documentation, including OpenSpec artifacts, in English. Translation values and user-generated content retain their own languages.
- Stop affected work and report any confirmed backend contract gap instead of inventing endpoints, fabricating data, or modifying the backend.

## Capabilities

### New Capabilities

- `forum-application`: Elm application routing, backend integration, account flows, discovery, discussions, profiles, search, notifications, media, and management.
- `localized-interface`: Locale selection, complete translation catalogs, formatting, bidirectional text, complex-script input, and English engineering documentation.
- `accessible-material-interface`: Responsive Material components and testable accessibility behavior across all supported workflows.

### Modified Capabilities

None. This repository has no existing main capability specifications.

## Impact

Creates the Elm application, CSS design tokens and components, a minimal browser integration bridge, build/test configuration, and English developer documentation. Uses the existing backend at `/media/btr/data/xyh/code/go/mygo-projects/commune-backend` without API or database changes. Deployment requires same-origin HTTPS API routing and SPA route fallback. Browser integration tests require a seeded backend and explicitly configured registration, mail, and media services where exercised. No implementation is included in this planning change.

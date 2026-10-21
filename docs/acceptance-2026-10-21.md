# Acceptance evidence: 2026-10-21

## Environment

- Elm 0.19.1 with dependencies pinned in `elm.json`
- Node.js 24.22.0 and dependencies pinned in `package-lock.json`
- Chromium supplied by the host
- Isolated PostgreSQL 18.6 for real-backend acceptance
- One-time HTTPS proxy at `localhost:8443` forwarding API calls to the real backend at `127.0.0.1:18080`

## Automated results

- 11 JavaScript tests passed: generated asset identity, lossless version normalization, locale and plural formatting, invalid dates, storage denial, catalog consistency, missing keys, placeholder mismatch, and release retention.
- 20 Elm tests passed: DTO decoding, numeric/string revisions, safe URLs, route parsing and pagination, locale negotiation, and race-safe request-state transitions.
- 36 mock-browser tests passed in the development suite and one real-backend test was skipped by default: discovery, auth and verification, invalid credentials, source-backed edit conflict, community creation, Chinese search, likes, deletion confirmation, uploads, profile/avatar, notifications, management permissions and endpoints, rich-content sanitization, API error mapping, keyboard focus, dialogs, locale changes, RTL, reduced motion, forced colors, and enlarged text/text spacing.
- 35 mock-browser tests passed against the production preview; the excluded test is the development-only RTL query injection.
- The real-backend test passed separately with an isolated database and HTTPS proxy. It covered login/session/CSRF, community creation, topic publication, media upload, source editing, likes, management actions, second-account reply, profile persistence, search, notification projection, and disabled registration.
- The active frontend change and archived localization main spec validate strictly. The frontend formatter check and translation generation consistency check pass.

## Real-backend dependencies

The test site had registration disabled and media plus participation workers enabled. The registration-disabled response was verified. The enabled registration path requires a configured SMTP test mailbox and was not exercised against a real mailbox. No external federation peer, remote media fetch, or operator-managed mail service was available.

## Manual limitations

The following remain unverified and must not be described as full WCAG conformance:

- NVDA with Firefox on Windows
- VoiceOver with Safari on macOS and iOS
- Real hardware Chinese IME candidate selection across operating systems
- Native OS text scaling and browser zoom beyond the automated text-spacing/reflow checks
- Independent linguistic review of all three catalogs
- Live cross-server federation and private remote-media behavior

Automated axe runs and keyboard/browser emulation passed for the implemented routes and states. The backend repository was not modified.

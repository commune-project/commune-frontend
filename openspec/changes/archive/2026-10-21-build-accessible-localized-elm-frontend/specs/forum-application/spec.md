## Purpose

Provide a complete browser forum experience against Commune's existing site-scoped APIs while preserving server permissions, privacy, and content semantics.

## ADDED Requirements

### Requirement: Navigable application and discovery
The application SHALL provide bookmarkable routes for latest discussions, community directory and detail, discussion detail, search, account flows, profiles, notifications, editors, and community management. Browser back, forward, and direct loading SHALL work. Lists SHALL support the API's offset pagination without inventing totals or unsupported sorting.

#### Scenario: Direct discussion navigation
- **WHEN** a reader loads a discussion URL directly and returns to the previous list
- **THEN** the application loads the authorized discussion and restores the list route and pagination context

#### Scenario: Empty or unavailable collection
- **WHEN** a collection is empty or its request fails
- **THEN** the interface distinguishes empty, loading, and error states and offers an appropriate retry without displaying fabricated content

### Requirement: Session and verified registration
The application SHALL support username/email login, session restoration, logout, registration, verification resend, and password selection from `/verify-email#token=...`. Confirmation SHALL precede a separate login. Disabled registration and rate limits SHALL have localized outcomes. Verification tokens SHALL remain out of query strings, logs, and persistent storage and SHALL be removed from browser history after capture.

#### Scenario: Email ownership confirmation
- **WHEN** an email owner opens a verification link and submits a valid password
- **THEN** the frontend sends the fragment token to confirmation and offers login after success without claiming an automatic session

#### Scenario: Session expires
- **WHEN** an authenticated operation returns 401
- **THEN** the application clears protected visible state and offers reauthentication without silently retrying the mutation

### Requirement: Discussions and editing
The application SHALL display topics and paginated direct replies, allow expanding nested replies, and support authorized creation, reply, editing, deletion, and like/undo. It SHALL display server counts and permissions, refresh interaction metadata after mutations, and read editing values from the source endpoint. Editing SHALL preserve legacy content format unless explicitly changed.

#### Scenario: Edit a Markdown discussion
- **WHEN** an authorized author opens the editor
- **THEN** the original title, body, format, and attachment identifiers are loaded from source and submitted without reconstructing source from display HTML

#### Scenario: Permission is revoked
- **WHEN** a formerly permitted mutation returns 403 or a protected read returns 404
- **THEN** the frontend explains the unavailable action without revealing restricted metadata, refreshes applicable permissions, and does not report success

### Requirement: Attachments and safe rich content
The application SHALL upload post/avatar media using the documented multipart contract, retain returned references, bind attachment IDs to mutations, and render only sanitized display HTML through an allowlisted renderer. Editor source SHALL never be injected as HTML. Remote public images SHALL use no-referrer behavior; private media SHALL use authorized backend references without anonymous fallback.

#### Scenario: Upload fails
- **WHEN** an attachment upload is rejected or unavailable
- **THEN** the editor retains the unsent text, identifies the failed file, and does not attach a fabricated upload ID

### Requirement: Profiles search and notifications
The application SHALL provide public local profiles, own-profile editing and avatar upload, literal post/community search, eligible notifications, unread count, and read actions. Mark-all-read SHALL use the received snapshot cursor. It SHALL not imply global remote discovery or complete federation totals.

#### Scenario: Notifications arrive after a snapshot
- **WHEN** a user marks a loaded notification snapshot read
- **THEN** the request uses that snapshot cursor and subsequent refresh retains later arrivals as unread

### Requirement: Community creation and management
The application SHALL support community creation with the documented immutable federation mode and valid policy pairs. Authorized users SHALL manage policies, paginated member/manager rosters, and moderation operations exposed by the API. Management authority SHALL not imply membership or posting permission. Operations addressed to a post ID SHALL not imply an unavailable moderation queue.

#### Scenario: Manager has no posting membership
- **WHEN** community permissions permit management but prohibit posting
- **THEN** management tools are available while the compose action remains unavailable

### Requirement: Contract fidelity and secure transport
Browser requests SHALL use same-origin HTTPS sessions and CSRF headers for authenticated mutations, never store session secrets in browser storage, handle 400/401/403/404/405/409/429/503 and network failures, and prevent stale responses from repopulating protected state after logout. A confirmed required API gap SHALL stop further feature implementation and be reported to the user before work resumes; the backend SHALL remain unchanged.

#### Scenario: Required backend capability is missing
- **WHEN** implementation establishes that a required workflow cannot use an existing endpoint
- **THEN** work stops with the missing contract, evidence, and affected workflow reported, without mock production behavior or backend edits

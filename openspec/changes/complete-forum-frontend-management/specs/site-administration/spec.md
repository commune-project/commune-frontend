## Purpose

Provide a role-gated management workspace for the site resolved by the current browser authority, so administrators can operate the moderation and voting capabilities exposed by that site's API without implying deployment-wide control.

## ADDED Requirements

### Requirement: Current-site management access
The application SHALL expose a current-site management destination only when the authenticated identity has site-administrator or deployment-superadministrator authority. Direct access without authentication SHALL request login, and direct access without either role SHALL show a localized forbidden state without issuing unauthorized management reads. Every management request SHALL remain scoped to the site resolved from the current browser authority.

#### Scenario: Ordinary account opens management
- **WHEN** an authenticated account without administrative roles opens the current-site management route
- **THEN** the application denies access and does not load vote settings, reports, moderation history, or bans

#### Scenario: Deployment administrator opens another site
- **WHEN** a deployment administrator account is authenticated only for its own site and opens another site's management route
- **THEN** the other site does not inherit that session or present deployment-wide data

### Requirement: Site vote settings
The management workspace SHALL display the resolved site's current upvote and downvote availability and allow an authorized administrator to update either setting. The application SHALL show the returned full settings after a successful partial update and SHALL explain that disabled directions affect aggregates, viewer vote state, ranking, and new mutations.

#### Scenario: Disable downvotes
- **WHEN** a site administrator disables downvotes
- **THEN** the management view shows downvotes disabled and ordinary post views stop offering new downvotes while retaining permission to clear an existing downvote

#### Scenario: Vote settings update fails
- **WHEN** a vote-settings request is rejected or unavailable
- **THEN** the form retains the current submitted values for correction, reports the localized failure, and does not present the update as saved

### Requirement: Report review
The management workspace SHALL list paginated reports by optional state and community scope. It SHALL display target kind, target ID, reason, state, resolution note, and creation time without inventing target content that the reviewer cannot read. An authorized reviewer SHALL resolve or reject an open report with an optional note and SHALL refresh the list after success or conflict.

#### Scenario: Filter open reports
- **WHEN** an administrator selects the open state
- **THEN** the report request includes that state and the rendered page contains only returned rows

#### Scenario: Resolve a report
- **WHEN** an administrator resolves an open report with a note
- **THEN** the application refreshes the report queue and moderation history and reports success

#### Scenario: No report detail route
- **WHEN** an administrator opens a report row
- **THEN** the application uses the inline list presentation unless the backend exposes a supported detail route

### Requirement: Moderation history
The management workspace SHALL provide a paginated, newest-first moderation log with optional community filtering. It SHALL display returned action, acting Actor URI, target kind, target ID, reason, and creation time, and SHALL provide no edit or delete controls. Community IDs that the API does not return SHALL not be inferred from unrelated content.

#### Scenario: Filter community history
- **WHEN** an administrator supplies a community ID filter
- **THEN** the request includes that filter and the interface does not imply a total count

#### Scenario: Missing community field
- **WHEN** a moderation row does not include a community ID
- **THEN** the interface omits the community label rather than deriving one from another record

### Requirement: Site ban actions
The management workspace SHALL provide forms to create and remove a site ban using an Actor URI, non-empty reason, and optional RFC 3339 expiry. It SHALL distinguish creation from unbanning, preserve input on validation failure, refresh moderation history after success, and explain that ban removal of an absent active ban may return not found.

#### Scenario: Create a temporary ban
- **WHEN** an administrator submits a valid Actor URI, reason, and future expiry
- **THEN** the application reports success and refreshes moderation history

#### Scenario: Unban missing active ban
- **WHEN** an unban request returns not found
- **THEN** the interface explains that no active ban matched and does not claim that a ban was removed

### Requirement: Deferred deployment management
The application SHALL NOT present a deployment-wide site, account, role, cross-site report, cross-site moderation, or site-switching workspace until the backend exposes supported contracts for those workflows. The current-site management workspace SHALL identify itself as current-site scoped and SHALL not aggregate data from multiple hosts.

#### Scenario: No deployment directory
- **WHEN** a deployment superadministrator uses the implemented management workspace
- **THEN** only current-site capabilities are offered and no unavailable global site or account directory is shown

#### Scenario: Backend prerequisite remains missing
- **WHEN** implementation requires a deployment-wide capability without a documented endpoint or cross-site session model
- **THEN** the deployment workflow remains out of scope and is reported as a backend dependency

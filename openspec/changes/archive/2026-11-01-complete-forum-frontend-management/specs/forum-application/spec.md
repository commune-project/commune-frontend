## MODIFIED Requirements

### Requirement: Navigable application and discovery
The application SHALL provide bookmarkable routes for latest discussions, community directory and detail, discussion detail, search, account flows, profiles, notifications, editors, community management, account content collections, personal blocks, password recovery and change, and current-site administration. Browser back, forward, and direct loading SHALL work. Lists SHALL support the API's offset pagination without inventing totals or unsupported sorting.

#### Scenario: Direct discussion navigation
- **WHEN** a reader loads a discussion URL directly and returns to the previous list
- **THEN** the application loads the authorized discussion and restores the list route and pagination context

#### Scenario: Empty or unavailable collection
- **WHEN** a collection is empty or its request fails
- **THEN** the interface distinguishes empty, loading, and error states and offers an appropriate retry without displaying fabricated content

#### Scenario: Protected route without a session
- **WHEN** an anonymous reader opens an account collection, personal block, password change, or management route
- **THEN** the application explains that authentication is required and does not issue protected reads or mutations

### Requirement: Discussions and editing
The application SHALL display topics and paginated threaded replies, allow expanding reply descendants, and support authorized creation, reply, editing, deletion, voting, save, read, personal hide, report, and like/undo compatibility actions. It SHALL display server counts and permissions, refresh interaction metadata after mutations, and read editing values from the source endpoint. Editing SHALL preserve legacy content format unless explicitly changed.

#### Scenario: Edit a Markdown discussion
- **WHEN** an authorized author opens the editor
- **THEN** the original title, body, format, and attachment identifiers are loaded from source and submitted without reconstructing source from display HTML

#### Scenario: Permission is revoked
- **WHEN** a formerly permitted mutation returns 403 or a protected read returns 404
- **THEN** the frontend explains the unavailable action without revealing restricted metadata, refreshes applicable permissions, and does not report success

#### Scenario: Interaction metadata changes
- **WHEN** a vote, save, read, or personal-hide mutation succeeds
- **THEN** the visible post is refreshed or patched from authoritative server metadata rather than retaining stale counts or viewer state

### Requirement: Community creation and management
The application SHALL support community creation with the documented immutable federation mode and valid policy pairs. Authorized users SHALL manage read, post, and follow policies, paginated member and manager rosters, pending follow requests, community-scoped reports and moderation logs, community bans, and moderation operations exposed by the API. Management authority SHALL not imply membership or posting permission. Operations addressed to a post ID SHALL not imply an unavailable moderation queue.

#### Scenario: Manager has no posting membership
- **WHEN** community permissions permit management but prohibit posting
- **THEN** management tools are available while the compose action remains unavailable

#### Scenario: Follow approval changes membership
- **WHEN** a manager accepts a pending follow request
- **THEN** the application refreshes the pending queue and member roster and reflects that approval may also grant membership

#### Scenario: Community moderation scope
- **WHEN** a community manager opens reports, moderation history, or bans for the managed community
- **THEN** only that community's review controls are available and site-wide controls remain unavailable without site authority

## ADDED Requirements

### Requirement: Post voting and content state
The application SHALL expose upvote, downvote, and clear-vote actions using the documented score values and current site vote settings. It SHALL expose save, mark-read, personal-hide, and personal-unhide actions where the corresponding permission is true. Disabled vote directions SHALL not be offered as mutations. The compatibility like action SHALL remain available only where its permission permits and SHALL be presented as an upvote alias rather than a separate score.

#### Scenario: Switch from upvote to downvote
- **WHEN** a reader who has upvoted a post chooses downvote
- **THEN** the application sends the downvote score, then displays the refreshed `voted_by_me`, `upvotes`, `downvotes`, and `score`

#### Scenario: Clear an existing vote after a direction is disabled
- **WHEN** a site disables downvotes while the reader has an existing downvote
- **THEN** the application does not offer a new downvote but still permits clearing the existing vote

#### Scenario: Personal hide is distinct from site hide
- **WHEN** a reader personally hides a post
- **THEN** the interface reports the post as hidden for that account and does not describe it as hidden site-wide

### Requirement: Recursive reply presentation
The application SHALL decode and display the API's recursive `children`, `depth`, and `child_count` fields. It SHALL paginate only root replies, preserve sibling ordering returned by the server, and allow readers to collapse or expand descendants without issuing duplicate requests for already loaded content. A filtered reply SHALL not be reconstructed from client-side assumptions.

#### Scenario: Deep reply tree
- **WHEN** a root reply contains descendants up to the requested maximum depth
- **THEN** the application renders the returned hierarchy and does not replace descendants with a second flat-fetch requirement

#### Scenario: Reply sorting changes
- **WHEN** a reader selects a documented reply sort mode
- **THEN** the root reply request includes that sort and the rendered sibling groups follow the returned order

### Requirement: Community follow lifecycle
The application SHALL display `follow_policy`, `follower_count`, `is_following`, `follow_state`, and `can_follow` without assuming a count is publicly visible. It SHALL offer follow or unfollow according to current permission and policy. Pending, accepted, rejected, and undone states SHALL be distinguished. A disabled follow policy SHALL leave unfollow available when the viewer is currently following.

#### Scenario: Approval-required follow
- **WHEN** a reader follows a community whose policy requires approval
- **THEN** the interface shows a pending state and does not claim membership or read access

#### Scenario: Restricted follower count
- **WHEN** the backend omits or zeroes a follower count for a restricted viewer
- **THEN** the interface does not infer or fabricate the actual count

### Requirement: Account content collections
The application SHALL provide bookmarkable paginated views for saved, read, hidden, and liked posts. Each view SHALL use the standard post representation and current permissions. The application SHALL provide direct controls to remove saved state, clear personal hidden state, and open available posts. Unavailable posts omitted by the backend SHALL not be reconstructed or cached into the collection.

#### Scenario: Saved list after access loss
- **WHEN** a saved post is no longer readable by the account
- **THEN** the backend omits it and the interface does not retain its title, body, author, or counts in the refreshed page

#### Scenario: Downvote is absent from liked posts
- **WHEN** the account has an active downvote but no active upvote on a post
- **THEN** that post is not presented in the liked collection

### Requirement: Personal blocking
The application SHALL let an authenticated account list, add, and remove personal blocks for person Actor URIs, community IDs, and normalized instance hostnames. It SHALL validate the selected kind before submission, distinguish personal blocks from site-administrator blocks, and refresh visible lists after successful changes. The application SHALL present server rejection of self blocks, own-site instance blocks, malformed targets, and unreadable communities as localized failures.

#### Scenario: Block a community
- **WHEN** an account adds a valid community block
- **THEN** the block appears in the account list and content filtered by the backend disappears on the next read without changing other accounts' views

#### Scenario: Site-wide block is not implied
- **WHEN** a reader creates a personal person, community, or instance block
- **THEN** the interface does not describe the target as blocked for the whole site

### Requirement: Reporting and moderation feedback
The application SHALL let authenticated readers report readable posts, communities, and persons with a reason of 1 to 1000 Unicode code points. It SHALL not offer self-reporting and SHALL use target IDs and optional community scope according to the target. Authorized managers and administrators SHALL list reports by state and optional community, resolve or reject open reports with an optional note, and handle idempotent or conflicting resolutions.

#### Scenario: Report submission
- **WHEN** a reader submits a valid report for a readable post
- **THEN** the application reports success without exposing private moderation state and does not imply that the report is resolved

#### Scenario: Conflicting resolution
- **WHEN** a reviewer resolves a report that another reviewer already resolved differently
- **THEN** the interface reports a conflict and refreshes the report state instead of claiming success

### Requirement: Moderation history and bans
The application SHALL display moderation log pages in the backend's newest-first order with optional community filtering and pagination. Authorized reviewers SHALL create and remove community bans or site bans using an Actor URI, reason, and optional RFC 3339 expiry. The application SHALL not claim that ban mutation endpoints provide an active-ban inventory or that the moderation log is editable.

#### Scenario: Site ban expires
- **WHEN** a site ban is created with an expiry
- **THEN** the interface presents the expiry as the ban end and does not offer an edit operation not provided by the API

#### Scenario: Moderation log remains read-only
- **WHEN** a reviewer views moderation history
- **THEN** entries are displayed without edit or delete controls

### Requirement: Notification target routing
The application SHALL decode `target_kind` and `target_id` for every notification and route post, report, moderation, community, and person targets according to the destination the current viewer is authorized to open. A report or moderation notification SHALL be display-only when no target detail route is available. The application SHALL retain the existing mark-read and snapshot mark-all-read behavior.

#### Scenario: Report resolution notification
- **WHEN** a reporter receives a notification with `target_kind` of `report`
- **THEN** the interface identifies it as a report event and does not construct a post URL from the report ID

#### Scenario: Moderation notification target
- **WHEN** a notification targets a person Actor URI
- **THEN** the interface does not expose an unauthorized profile link merely because the target is present

### Requirement: Password reset and change
The application SHALL provide a generic password-reset request flow, a token-based reset confirmation flow, and an authenticated password-change form. Reset requests SHALL not reveal whether an email belongs to an account. Reset confirmation SHALL remove the token from browser history after capture. Password change SHALL require the current password, preserve the current session on success, and clear password fields after completion.

#### Scenario: Unknown reset email
- **WHEN** a user requests a password reset for an address with no matching account
- **THEN** the interface shows the same generic acceptance state used for a known address

#### Scenario: Password reset confirmation
- **WHEN** a user opens a valid reset link and submits a valid new password
- **THEN** the application consumes the token, removes it from history, and directs the user to log in again

#### Scenario: Password change fails
- **WHEN** an authenticated password change is rejected
- **THEN** the form retains the selected fields as appropriate for correction, reports the localized failure, and does not claim that other sessions were revoked

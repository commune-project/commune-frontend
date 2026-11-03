## MODIFIED Requirements

### Requirement: Profiles search and notifications
The application SHALL provide public local profiles, own-profile editing, Markdown biography authoring, and avatar upload, literal post/community search, eligible notifications, unread count, and read actions. Mark-all-read SHALL use the received snapshot cursor. It SHALL not imply global remote discovery or complete federation totals. The biography field SHALL use the shared Markdown authoring surface, preserve unsent text when a save fails, and submit the edited Markdown source.

#### Scenario: Notifications arrive after a snapshot
- **WHEN** a user marks a loaded notification snapshot read
- **THEN** the request uses that snapshot cursor and subsequent refresh retains later arrivals as unread

#### Scenario: Biography authoring preserves source
- **WHEN** an authenticated reader edits the biography in profile settings and saves it
- **THEN** the profile request receives the edited Markdown source, mention candidates are available while editing, and a rejected save retains the unsent biography

### Requirement: Post voting and content state
The application SHALL expose upvote, downvote, and clear-vote actions through one merged vote control on each post. The control SHALL display the net score from `score`, expose the selected direction from `voted_by_me`, and offer each direction only where `can_upvote` or `can_downvote` permits it. It SHALL submit `1`, `-1`, or `0` to the documented vote endpoint, and repeating the selected direction SHALL clear the vote. A direction disabled by site settings SHALL not be offered as a new mutation, but an existing vote in that direction SHALL remain clearable. The compatibility like action SHALL be presented as an upvote alias and SHALL NOT introduce a second visible score.

The application SHALL also expose save, mark-read, personal-hide, and personal-unhide actions where the corresponding permission is true. Disabled vote directions SHALL not be offered as mutations.

#### Scenario: Switch from upvote to downvote
- **WHEN** a reader who has upvoted a post chooses downvote
- **THEN** the application sends the downvote score, then displays the refreshed `voted_by_me`, `upvotes`, `downvotes`, and `score`

#### Scenario: Clear an existing vote after a direction is disabled
- **WHEN** a site disables downvotes while the reader has an existing downvote
- **THEN** the application does not offer a new downvote but still permits clearing the existing vote

#### Scenario: Merged vote score
- **WHEN** a post has three active upvotes and one active downvote
- **THEN** the post card displays one net score of two and does not display a separate like count beside the downvote control

#### Scenario: Like alias selects upvote
- **WHEN** a compatibility like succeeds for a post
- **THEN** the merged control shows the upvote direction as selected and does not create a second score

#### Scenario: Personal hide is distinct from site hide
- **WHEN** a reader personally hides a post
- **THEN** the interface reports the post as hidden for that account and does not describe it as hidden site-wide

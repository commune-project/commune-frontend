## Why

The backend now exposes voting, threaded replies, follows, reports, moderation logs, bans, personal blocks, saved/read/hidden state, password recovery, and site vote settings, but the Elm client still implements the previous forum contract. This leaves ordinary users and site administrators unable to use the newly available workflows from the browser.

## What Changes

- Extend the domain decoders and state models for post votes, recursive reply trees, community follow state, notification targets, reports, moderation logs, bans, account content state, personal blocks, and site vote settings.
- Add browser actions for upvoting, downvoting, clearing votes, following communities, saving/reading/personally hiding posts, reporting content, blocking people/communities/instances, resetting a forgotten password, and changing an authenticated password.
- Add paginated account collections for saved, read, hidden, and liked posts, plus an account blocks page.
- Replace the flat-only reply presentation with recursive `children` rendering and documented reply sorting and depth controls.
- Add a role-gated current-site management center at `/admin` with overview, vote settings, report review, moderation log, and site-ban actions.
- Extend community management with `follow_policy`, pending follow requests, community-scoped reports and moderation logs, and community-ban actions.
- Add permission-aware navigation entries and localized interface messages for every new workflow.
- Keep deployment-wide management out of scope until the backend exposes cross-site site/account/role APIs, site switching or deployment-scoped sessions, active-ban lists, report detail, and cross-site report/modlog aggregation.
- Do not modify backend code, invent replacement endpoints, or simulate deployment-wide data from the current site.

## Capabilities

### New Capabilities

- `site-administration`: Role-gated current-site administration for vote settings, reports, moderation history, and site bans.

### Modified Capabilities

- `forum-application`: Expand discovery, discussion, account, community, notification, and management behavior to consume the complete current backend browser contract.
- `accessible-material-interface`: Add accessible navigation, management layouts, and icon-and-label controls for votes, save, personal hide, report, blocks, report resolution, and moderation actions.

## Impact

- Affects `src/Domain.elm`, `src/Route.elm`, application composition and routing, shell navigation, post/community/notification/auth/profile features, community management, new account and site-administration features, shared post cards, formatting, translations, tests, styles, and architecture/backend-integration documentation.
- Uses only existing same-origin `/api/v1` browser endpoints and current site-scoped sessions; adds no backend, dependency, storage, or deployment change.
- Preserves existing routes and request contracts while adding bookmarkable account and site-management routes.
- Defers the deployment management center and its required backend contracts to a later change.

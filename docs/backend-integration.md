# Backend integration

The frontend consumes the sibling `commune-backend` browser API without modifying backend code. The authoritative contracts are `docs/api.md`, `docs/authentication.md`, `docs/forum-browser-api.md`, and `docs/participation-api.md` in that repository.

All requests are same-origin. Browser session cookies are sent automatically. The client reads `__Host-commune_csrf` only for mutating requests and never writes sessions or CSRF values to browser storage. Responses are interpreted by committed DTO decoders and stable HTTP statuses; server error prose is not treated as localized interface text.

The main request groups are:

| Area | Endpoints |
| --- | --- |
| Session | `/api/v1/auth/session`, `/login`, `/logout` |
| Registration | `/api/v1/auth/register`, `/verification/resend`, `/verification/confirm` |
| Discovery | `/api/v1/topics`, `/api/v1/communities`, `/api/v1/communities/{id}/topics` |
| Posts | `/api/v1/posts/{id}`, `/replies`, `/vote`, `/likes`, `/save`, `/read`, `/hide-for-me`, `/source`, `/hide`, `/import` |
| Search | `/api/v1/search?kind=posts|communities&q=...` |
| Notifications | `/api/v1/notifications`, `/unread-count`, `/{id}/read`, `/read-all` |
| Profiles | `/api/v1/profile`, `/api/v1/profiles/{username}` |
| Media | `/api/v1/media`, `/api/v1/media/private/{id}` |
| Account content | `/api/v1/account/saved`, `/read`, `/hidden`, `/liked`, `/blocks` |
| Community management | `/api/v1/communities/{id}/policy`, `/follow-requests`, `/members`, `/managers`, `/bans`, `/removals`, `/submissions` |
| Moderation | `/api/v1/reports`, `/reports/{id}/resolve`, `/modlog`, `/admin/bans` |
| Site administration | `/api/v1/site/vote-settings`, `/api/v1/admin/vote-settings` |
| Password | `/api/v1/auth/password/reset`, `/reset/confirm`, `/change` |
| Context | `/api/v1/contexts/{id}/backfill` |

Writes carry the current CSRF value. Editing reads `/source` and sends its revision as the numeric `expected_version`; a 409 `edit_conflict` keeps the draft and fetches fresh source for comparison. No write is automatically retried.

Management routes remain scoped to the site resolved by the browser authority. Deployment-wide site, account, role, active-ban inventory, report-detail, and cross-site moderation contracts are not currently available and are not simulated by the frontend.

The isolated real-backend test seeds a site, an administrative account, and an ordinary account. It exercises sessions, CSRF, community creation, topic publication, valid image upload/binding, source-backed editing, likes, management, second-account replies, profile updates, search, notification projection, and the registration-disabled response. SMTP delivery and external federation are not exercised by the default fixture server.

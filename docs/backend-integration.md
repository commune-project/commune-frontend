# Backend integration

The frontend consumes the sibling `commune-backend` browser API without modifying backend code. The authoritative contracts are `docs/api.md`, `docs/authentication.md`, `docs/forum-browser-api.md`, and `docs/participation-api.md` in that repository.

All requests are same-origin. Browser session cookies are sent automatically. The client reads `__Host-commune_csrf` only for mutating requests and never writes sessions or CSRF values to browser storage. Responses are interpreted by committed DTO decoders and stable HTTP statuses; server error prose is not treated as localized interface text.

The main request groups are:

| Area | Endpoints |
| --- | --- |
| Session | `/api/v1/auth/session`, `/login`, `/logout` |
| Registration | `/api/v1/auth/register`, `/verification/resend`, `/verification/confirm` |
| Discovery | `/api/v1/topics`, `/api/v1/communities`, `/api/v1/communities/{id}/topics` |
| Posts | `/api/v1/posts/{id}`, `/replies`, `/likes`, `/source`, `/hide`, `/import` |
| Search | `/api/v1/search?kind=posts|communities&q=...` |
| Notifications | `/api/v1/notifications`, `/unread-count`, `/{id}/read`, `/read-all` |
| Profiles | `/api/v1/profile`, `/api/v1/profiles/{username}` |
| Media | `/api/v1/media`, `/api/v1/media/private/{id}` |
| Management | `/api/v1/communities/{id}/policy`, `/members`, `/managers`, `/removals`, `/submissions` |
| Context | `/api/v1/contexts/{id}/backfill` |

Writes carry the current CSRF value. Editing reads `/source` and sends its revision as the numeric `expected_version`; a 409 `edit_conflict` keeps the draft and fetches fresh source for comparison. No write is automatically retried.

The isolated real-backend test seeds a site, an administrative account, and an ordinary account. It exercises sessions, CSRF, community creation, topic publication, valid image upload/binding, source-backed editing, likes, management, second-account replies, profile updates, search, notification projection, and the registration-disabled response. SMTP delivery and external federation are not exercised by the default fixture server.

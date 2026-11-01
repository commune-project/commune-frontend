## Context

See `proposal.md` for motivation and the delta specs for observable behavior. The current client is an Elm `Browser.application` composed from explicit feature modules. `Domain.elm` owns DTO decoding, `Route.elm` owns bookmarkable URLs, `App.Routing` starts protected reads, `App.Features` applies feature outcomes, and `App.Interaction` currently propagates completed like state into every visible post representation.

The backend browser API remains site-scoped by the request authority. New mutation routes commonly return `204`, while post reads return authoritative vote and viewer state. Report and moderation rows do not expose `community_id`, report detail does not exist, and ban routes do not provide an active-ban inventory. Deployment-wide directory, role, aggregation, and cross-site session contracts are absent.

## Goals / Non-Goals

**Goals:**

- Consume every current backend browser capability that can be implemented against the resolved site.
- Keep post actions consistent across latest, community, search, discussion, and account collection surfaces.
- Keep feature ownership and dependency direction consistent with the existing architecture.
- Gate management routes and navigation with both identity roles and server responses.
- Preserve localization, accessibility, CSRF, route epoch, and session cleanup conventions.

**Non-Goals:**

- Do not add deployment-wide management, site switching, account/role directories, active-ban inventories, report detail, or cross-site aggregation.
- Do not change backend code or create mock production data.
- Do not replace the existing editor, rich-content renderer, localization system, or browser bridge.
- Do not add a client-side authorization cache or treat DTO permissions as mutation authority.

## Decisions

### 1. Extend DTOs additively and tolerate older fixtures

Add typed domain records for vote settings, reports, moderation log entries, ban input, account blocks, follow requests, and account content sources. Extend post, community, and notification decoders with the new fields. Additive fields use safe defaults where omission remains valid, including zero vote counts, false personal flags, empty children, `follow_state` of `none`, and notification target fallback from `post_id`.

Use the existing identifier decoder for backend numeric IDs so existing notification and management routes can continue to represent IDs as strings. Report resolution and ban mutations keep IDs in their path or payload without recomputing them.

Alternative: make every new field mandatory immediately. This was rejected because it would break existing mock-browser fixtures and does not improve server authority. The backend always rechecks permissions.

### 2. Use explicit account and administration routes

Add bookmarkable routes for:

- `/account/saved`
- `/account/read`
- `/account/hidden`
- `/account/liked`
- `/account/blocks`
- `/reset-password`
- `/reset-password/confirm#token=...`
- `/settings/password`
- `/admin`
- `/admin/reports`
- `/admin/modlog`
- `/admin/bans`
- `/admin/settings`

Use explicit administration subroutes instead of one query-string tab. This keeps direct loading, browser history, page titles, focus targets, and test selectors deterministic. The current community route remains `/communities/:id/manage`.

Alternative: one `/admin?tab=...` route. It reduces route constructors but makes each management surface share a large conditional page and weakens bookmark semantics.

### 3. Separate account collections from personal blocks

Create a feature for paginated account content collections and a separate feature for personal block management. The content feature owns the selected source, page remote state, and post action callbacks. The block feature owns the block-kind form, target input, list remote state, and add/remove busy keys.

This split keeps the two forms and URLs independent while both remain authenticated account features. Sharing a single large Account feature would mix unrelated page lifecycles and make route resets less precise.

### 4. Centralize cross-surface post mutations in the Post feature

Extend the existing Post feature to own busy keys and mutation commands for vote, save, read, personal hide, and report launch. Shared post-card callbacks are supplied by the application adapter, so latest, community, search, discussion, and account collection cards use the same actions.

After a `204`, request the post detail and apply the authoritative returned post to all visible copies through an expanded `App.Interaction` patch. When personal hiding succeeds on a feed or collection where the post must disappear, refresh the current route rather than leaving a locally contradictory row. Direct post detail may retain a personally hidden post because the backend returns `hidden_by_me`.

Alternative: optimistic count arithmetic in every list. It avoids a refresh but can drift when vote settings change or another actor votes concurrently. The backend DTO is the authority.

### 5. Decode and render the returned reply tree directly

Decode `children` recursively and render returned descendants from the root reply response. Remove the separate per-parent nested request path for normal tree presentation. Reply sort and maximum depth become route-backed query parameters. Collapsing a subtree only changes local visibility and does not refetch already loaded data.

Alternative: retain per-parent requests while also decoding children. That creates two sources of truth and redundant requests for the same thread.

### 6. Use one accessible report workflow

Create a report feature that owns target kind, target ID, optional community ID, reason, validation, busy state, and completion feedback. The application shell renders its accessible dialog and opens it from post, community, or person actions. Report creation remains separate from report review.

Alternative: embed a separate report form on each page. This duplicates validation and dialog focus behavior and risks inconsistent target payloads.

### 7. Extend Auth for password recovery and change

Extend the Auth feature with generic reset request, fragment-token confirmation, and authenticated password change states. Capture the confirmation token from the fragment during route load, replace browser history to remove it, and keep it only in feature state until submission. A successful confirmation clears the token and sends the user to login. A successful change clears password fields and leaves the current session active.

Alternative: create three unrelated password features. Auth already owns credential forms and verification-token handling, so reuse keeps security behavior together.

### 8. Build the current-site administration workspace as a dedicated feature

Create `Feature.SiteAdmin` with State, Update, and View modules. Each `/admin/*` route loads only the data needed for that surface. The application checks identity roles before protected reads; the server remains authoritative if roles changed or the identity is stale.

The overview links to available surfaces and identifies the workspace as current-site scoped. Vote settings use `/site/vote-settings` and `/admin/vote-settings`. Reports and modlog use paginated remote state and optional filters. Site bans use an action form and refresh modlog after success.

Do not render community labels that the API hides. Do not render an active-ban list. Do not infer deployment-wide counts or sites. A deployment administrator sees the same current-site workspace as a site administrator.

Alternative: place all administration in `Feature.CommunityManage`. This conflates community authority with site authority and makes route reset and navigation gating harder to reason about.

### 9. Expand community management in place

Extend `Feature.CommunityManage` with follow policy, follow-request pagination and decisions, community-scoped report and modlog filters, and community ban actions. Reuse the same report and modlog decoders as site administration but keep separate route-scoped state and authority controls. Follow approval refreshes both the pending queue and member roster.

Community management never renders site-only vote settings or site bans. Site administration may deep-link to a hosted community but does not replace that community's permission checks.

### 10. Keep navigation and page access role-aware without hiding failures

Navigation shows My content, Blocks, and current-site management according to authentication and roles. Anonymous direct access to protected routes shows the localized login-required state without issuing reads. Authenticated direct access to management without either role shows a localized forbidden state without issuing management reads. A backend `401` still clears protected state; a `403` or `404` remains localized in place.

### 11. Preserve mutation, pagination, and localization conventions

All mutations use the existing CSRF transport and never retry automatically. Mutations are keyed by action and target to prevent duplicate submission. Filters and offsets are represented in URLs where bookmarkability is expected. New strings are added to all three Fluent catalogs before generated accessors are refreshed. No new dependency is introduced.

## Risks / Trade-offs

- [Cross-surface post mutation state can become stale] -> Refresh authoritative post metadata and patch every visible representation; reload list surfaces when personal hiding changes membership.
- [Recursive DTOs can create large render trees] -> Rely on the backend maximum depth, keep root pagination, and render collapsed descendants lazily.
- [Additive decoders can conceal a backend regression] -> Use defaults only for documented additive fields and keep strict decoding for authoritative identities, IDs, timestamps, and pagination.
- [Management screens expose API gaps as broken controls] -> Omit community IDs, report detail, active-ban inventory, and deployment directory until contracts exist.
- [Password tokens or secrets leak] -> Capture the token from the fragment, replace history immediately, use password inputs, and never persist credentials in browser storage.
- [Role revocation after page load] -> Keep server checks authoritative and translate `403`/`401` without silently retrying.
- [Large feature modules exceed maintainability targets] -> Use dedicated SiteAdmin State/Update/View modules and split administration subviews where needed.
- [New action rows crowd compact post cards] -> Use accessible icon controls and an icon menu, keep 48-pixel targets, and test 320-pixel reflow.

## Migration Plan

1. Add domain records and additive decoders, route constructors, and fixture coverage.
2. Introduce shared post-action and report outcomes, then migrate post cards and interaction propagation.
3. Add account collections, blocks, and password recovery/change.
4. Replace flat reply expansion with recursive tree rendering and sort/depth controls.
5. Add community follow, follow review, scoped reports/modlog, and community bans.
6. Add the current-site administration feature and role-gated navigation.
7. Complete all locale catalogs, styles, architecture documentation, and browser acceptance coverage.

No data or backend migration is required. Deploy the frontend with a backend that provides the documented routes. Roll back by restoring the previous frontend build; backend data remains compatible because this change only reads and mutates through existing contracts.

## Open Questions

None. Deployment-wide management remains a separate future change after the backend exposes its required contracts.

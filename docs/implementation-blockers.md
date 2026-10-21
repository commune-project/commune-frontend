# Implementation blockers

## Resolved: concurrent author editing now has a conditional-write contract

Observed on 2026-10-21 while applying `build-accessible-localized-elm-frontend`, before application code was created. All implementation tasks remain unchecked.

The accepted design requires conflict recovery without silently overwriting another edit (design decision 2; task 6.2). The current backend exposes `updated_at` in the source response but does not accept an expected version on the author PATCH route. `docs/forum-browser-api.md` explicitly states that this timestamp is version context rather than an optimistic-lock precondition.

Evidence in `/media/btr/data/xyh/code/go/mygo-projects/commune-backend`:

- `internal/server/forum_posts.mygo`: `EditPostInput` accepts title, body, content_format, and attachment_ids only. `PostMutation` passes no client version to `EditResolvedContent` and does not check conditional request headers.
- `internal/server/forum.mygo`: `DecodeJSONBody` rejects unknown JSON fields, so a frontend-invented expected-version property is not supported.
- `internal/storage/post_edit.mygo`: `MutateAuthor` locks the current row, but `EditResolvedContent` updates by ID and non-deleted status without comparing the version the author originally read.

Reproduction implied by the actual write path: open the same post source in tabs A and B; save A; then save B using its older draft. Both writes can succeed, and B overwrites A. A row lock serializes writes but does not detect stale editor state. A source reread before PATCH still leaves a race and cannot guarantee the accepted behavior.

The blocking condition was resolved on 2026-10-21 by the backend's additive post-edit concurrency change. The current contract:

- Source responses include an exact positive signed 64-bit `version`.
- Author PATCH requests require that source `version` as `expected_version`.
- A stale write returns `409 {"error":"edit_conflict"}` without changing content, bindings, mentions, or queued Update activities.
- Frontend clients must retain revision digits losslessly, preserve the draft on conflict, and fetch fresh source for manual comparison rather than retrying the old draft automatically.

The backend reports PostgreSQL acceptance coverage for concurrent saves and attachment/mention rollback. This frontend repository did not modify or re-run the backend suite; the frontend implementation must preserve `version` exactly and must be verified against the revised API when the editor workflow is implemented.

## Why

The forum's authoring surfaces still use plain textareas, post timestamps can fall back to ISO after Elm re-renders, the two vote buttons expose different numbers with ambiguous labels, and section page headings dominate the content. The backend now exposes mention candidates and explicit vote semantics, so the frontend can make these interactions coherent without inventing API behavior.

## What Changes

- Add a shared Markdown authoring surface for topics, replies, post edits, and profile biographies, with a formatting toolbar and an accessible mention candidate list backed by `GET /api/v1/mentions/candidates`.
- Insert the complete handle returned by the candidate endpoint (`@username@domain`) so mentions work regardless of whether the account is local or remote. The editor will not depend on the backend's currently unimplemented bare local-handle shorthand.
- Merge upvote and downvote into one vote control that displays the net score, exposes the selected direction, and submits `1`, `-1`, or `0` to `POST /api/v1/posts/{id}/vote`.
- Render timestamps as localized absolute date and time values in the browser's time zone, removing the transient ISO fallback and the appended relative phrase.
- Reduce section page headings and preserve a larger heading only for entity pages such as post, community, and profile detail.
- Keep the change frontend-only. No backend, API, schema, or dependency changes are required.

## Capabilities

### New Capabilities

- `markdown-authoring`: shared source-first Markdown editing, formatting actions, mention candidate lookup and insertion, keyboard behavior, and accessibility across post and profile authoring surfaces.

### Modified Capabilities

- `forum-application`: profile biography authoring uses the shared Markdown surface, and post voting presents one current vote with a net score instead of separate like and downvote readings.
- `accessible-material-interface`: section page headings use a compact type scale, entity headings remain distinct, and the merged vote control retains 48 CSS pixel targets and localized accessible names.
- `localized-interface`: visible timestamps use localized absolute date and time values in the browser time zone and never revert to raw ISO text after a re-render.

## Impact

- Elm features and views under `src/Feature/Editor`, `src/Feature/Profile.elm`, `src/Feature/Post.elm`, `src/Ui/PostCard.elm`, `src/Ui/Layout.elm`, and `src/Ui/Formatting.elm`.
- A new shared authoring module, port commands for selection-aware insertion, `src/Ports.elm`, and the browser formatting bridge in `src/bootstrap.js`.
- Translation catalogs and generated accessors for mention status, toolbar labels, vote labels, and timestamp labels.
- Elm unit tests, JavaScript bridge tests, and Playwright browser tests. No backend or deployment changes.

This change deliberately excludes a live HTML preview or a contenteditable WYSIWYG mode. Markdown remains the authoritative editor source.

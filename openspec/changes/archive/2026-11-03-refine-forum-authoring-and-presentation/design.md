## Context

The current editor is a plain textarea in `Feature.Editor.View`, and profile biography is another plain textarea in `Feature.Profile`. The browser formatting bridge receives one synthetic sample time from `Ports.requestFormatting`, while each real post renders its ISO source until a DOM observer rewrites it. Post cards show a heart-shaped compatibility like with `like_count` and a separate downvote control whose adjacent number is actually `score`. All page-level views share the same large `h1` clamp.

The backend now provides `GET /api/v1/mentions/candidates` for authenticated mention lookup and `POST /api/v1/posts/{id}/vote` for score `1`, `-1`, and `0`. Candidates return a complete `acct`, have a 2–64 code point query, default to eight items, and exclude the viewer and blocked actors. Candidate lookup does not filter by `community_id` and does not discover unknown remote actors. The bare local mention shorthand remains a backend follow-up, so the frontend must not depend on it.

The change is frontend-only and must preserve Markdown as the authoritative source. It carries no data migration and must not alter server contracts.

## Goals / Non-Goals

**Goals:**

- Reuse one source-first Markdown authoring surface across topic, reply, edit, and profile biography workflows.
- Provide mention candidates with caret-aware insertion, keyboard operation, and localized non-blocking states.
- Make every visible post and administrative timestamp a localized absolute date/time in the browser time zone.
- Present one vote control with a net score and explicit direction state.
- Make section page headings compact while keeping entity detail headings distinct.
- Keep existing permissions, source versioning, attachment behavior, and API error handling intact.

**Non-Goals:**

- A live HTML preview, contenteditable WYSIWYG mode, or a client-side Markdown renderer.
- Backend changes for bare local mention shorthand, candidate community filtering, or new response fields.
- WebFinger or Actor discovery from the editor.
- A general typography redesign or changes to body text, post content headings, or application-bar branding.

## Decisions

### Shared authoring model

Create a reusable authoring feature with its own state, update, and view rather than duplicating mention and selection logic in Editor and Profile. The model owns the Markdown value, the current selection range, the active mention token, candidate state, and the selected candidate index. Editor and Profile store that model as part of their feature state and read its value when submitting. Parent updates receive a small outcome indicating whether the source changed so existing problem and conflict clearing can remain in the parent.

The view keeps the native textarea. Formatting actions compute a replacement for the stored selection and send a port command that replaces the range in the textarea, restores focus, sets the caret, and dispatches an input event. This avoids a contenteditable renderer and keeps server source, expected versions, and attachment bindings unchanged. The alternative of a JavaScript embedded editor was rejected because it would duplicate virtualization, accessibility, and translation ownership; a client Markdown preview was rejected because it would not match the server renderer without adding a second parser and sanitizer.

### Mention lookup and insertion

On value or selection changes, the authoring model finds the active `@` token before the caret. It requests candidates only when the token contains 2–64 Unicode code points, uses a 250 ms debounce and a monotonically increasing generation, and requests eight items. Candidate state is one of closed, loading, ready, empty, or unavailable. Stale responses and responses for a different token are discarded. The query is the token text after `@`; no `community_id` is sent because the endpoint does not filter by it.

Selection inserts `@` plus the returned `acct` plus one space, replacing the token through the caret. The full handle is deliberate: the endpoint returns a complete handle and the current backend resolver accepts it for local and remote candidates. The UI does not infer a local domain or rely on the bare local shorthand. The help text will describe complete handles. If the backend later implements bare local mentions, a separate change can shorten local insertion without changing this contract.

The candidate popup uses listbox semantics with an active descendant on the text area, pointer selection through non-blurring mouse-down handling, Arrow Up/Down, Enter or Tab, and Escape. Enter is ignored while `isComposing` is true. Candidate failures are non-blocking; submission still uses the source text. The existing composition guard in the browser bootstrap remains the final protection against premature submission.

### Timestamp ownership

Remove times from the Elm formatting sample and make the browser bridge the single timestamp formatter. Every timestamp renders as a semantic `<time datetime="..." data-commune-time>` element with the ISO source as its initial fallback. The bridge formats each element with `Intl.DateTimeFormat` using the active interface locale, the browser's time zone, `dateStyle: "medium"`, and `timeStyle: "short"`. It replaces the text only when the formatted value differs from the current text, which prevents observer loops and also repairs a value that Elm rewrote during a re-render. The observer watches child and character data changes under the application root, and the locale handler re-runs formatting after updating the document language.

The visible text is absolute only; the bridge does not append a relative phrase. The semantic `datetime` value remains the machine-readable timestamp. Invalid dates keep their original text. This interpretation treats “local version” as localized interface formatting in the viewer's time zone; a browser-language override can be a separate product decision without changing the formatter boundary.

### Merged vote control

Add a small presentation component that receives `score`, `votedByMe`, `canUpvote`, `canDownvote`, `canLike`, busy state, and a single vote callback. It renders an upvote button, the net score, and a downvote button as one bordered group. A direction is offered when its current permission is true or when the viewer already holds that vote and must be able to clear it. Both controls are disabled while a vote is in flight. The score is read from `score`, never from `like_count`, and the accessible group name includes the localized score meaning. The buttons expose the selected direction with `aria-pressed` and distinguish it with shape or surface as well as color.

Normal voting uses `POST /api/v1/posts/{id}/vote` with `1`, `-1`, or `0`. The compatibility like permission is treated as an upvote alias: when only `canLike` is available, the upvote direction uses the existing like endpoints; when `canUpvote` is available, it uses the vote endpoint. The old separate like score and the duplicate `Downvote · Downvote` label are removed. The post mutation refresh continues to replace the visible post with authoritative metadata. Alternative designs such as a popover or a cycling single button were rejected because they hide direction or make clearing less predictable.

### Heading hierarchy

Keep `pageHeading` as the compact default for section and authoring pages, and add an entity variant for post, community, and public profile detail. The section heading uses `clamp(1.5rem, 3vw, 1.75rem)`; the entity variant uses `clamp(1.75rem, 4vw, 2.25rem)`. The existing global `h1` clamp is removed so the class controls size. Both remain a single focused `h1`; only the type scale changes. This avoids editing every call site to pass a size and limits the larger treatment to pages where the title is the content identity.

### Testing

Add Elm unit tests for token detection, replacement, candidate generation handling, vote availability, and heading selection. Add JavaScript tests that assert absolute localized formatting, invalid-date fallback, and repeated formatting stability. Add Playwright coverage for toolbar insertion, mention keyboard navigation and insertion, profile biography authoring, merged vote state, timestamp stability after a vote refresh and locale switch, and computed heading sizes at desktop and 320 CSS pixels. Run the existing formatter, translation check, Elm compile and tests, JavaScript tests, and browser suite. No new runtime dependency is planned.

## Risks / Trade-offs

- [Caret-aware insertion with Elm's virtual DOM can desynchronize the textarea] → Keep the native textarea, replace ranges through one port command, dispatch a normal input event, and test selection and composition behavior in a real browser.
- [Mention detection can be noisy while typing or during IME composition] → Debounce, require two characters, use request generations, ignore composition Enter, and keep failures non-blocking.
- [Full handles are longer than the previous `@username` help text implied] → Update guidance to complete handles and treat bare local shorthand as a backend follow-up rather than silently relying on it.
- [Candidate results are deployment-wide known actors, not community members] → Describe them as mention candidates only; do not label them as members or imply access.
- [Removing relative times may reduce recency cues] → Preserve the semantic absolute timestamp and title metadata; relative time can be reintroduced later as a separate secondary label.
- [The timestamp observer can loop] → Compare the formatted value with the current text before writing and observe both child and character changes.
- [Vote permissions vary by site and existing vote direction] → Cover the permission matrix, including clearing a disabled existing direction, in unit and browser tests.
- [Compact headings can become too small for entity titles] → Keep a separate entity variant and test both section and detail pages at 320 CSS pixels and 400% zoom.

## Migration Plan

Ship as a normal frontend release with regenerated translation accessors and catalogs. No backend deployment, schema migration, or stored-data change is required. Rollback is the previous frontend build; stored Markdown, vote rows, and timestamps are unaffected. Deploy after the formatter, compile, translation, JavaScript, Elm, and browser checks pass, and retain the prior hashed translation catalogs during the release window.

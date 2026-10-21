# Architecture

The application uses Elm's `Browser.application` and explicit page state. `src/Route.elm` owns bookmarkable URLs and query parameters. `src/Domain.elm` decodes backend DTOs. `src/Api.elm` centralizes same-origin requests, JSON body transport, multipart uploads, and HTTP status-to-problem conversion. `src/Main.elm` owns session state, request generations, route-specific remote states, forms, mutations, and rendering.

Remote reads carry the current route epoch. A response from an older route or a superseded language request is discarded. Login and logout advance an authentication generation so old session or page responses cannot restore private state. Mutations never retry automatically; 401 clears protected state, 403 preserves the current permission explanation, and 409 returns control to the editor with its draft intact.

Session cookies remain HttpOnly. The JavaScript bootstrap reads only the non-HttpOnly CSRF cookie and sends it back through Elm for mutation headers. The server remains authoritative for permissions, CSRF, and membership. JavaScript is otherwise limited to browser preferences, dynamic catalog decoding, Intl formatting, focus requests, native dialog control, and IME composition protection.

Post display renders the server's sanitized HTML through an allowlisted Elm parser. Editing always uses the source endpoint and sends the exact expected version as a JSON number. The generated local-time display decorates semantic `<time datetime>` elements without changing stored timestamps.

Translations are generated from Fluent catalogs by Travelm Agency. Only selected JSON catalogs load at runtime. See `localization.md` for resource identity and failure behavior.

The responsive shell exposes a top application bar, desktop navigation, a native modal drawer on compact widths, a skip link, and route-focused headings. Shared CSS tokens cover Material color roles, spatial sizing, focus, forced colors, reduced motion, and script-aware font fallback. Native form controls, dialogs, lists, and landmarks are preferred over custom widgets.

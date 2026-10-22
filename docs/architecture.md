# Architecture

The application uses Elm's `Browser.application` and explicit feature state. `src/Main.elm` wires the program, coordinates navigation and shell events, and validates asynchronous responses before dispatching them. `src/Route.elm` owns bookmarkable URLs and query parameters. `src/Domain.elm` decodes backend DTOs. `src/Api.elm` centralizes same-origin requests, JSON body transport, multipart uploads, and HTTP status-to-problem conversion.

Remote reads and mutation responses carry the current route epoch. Main discards mismatched epochs, except for login/logout results, which must still complete after navigation. Session reads carry a separate authentication generation. Successful login/logout advance both generations; 401 session cleanup advances the authentication generation. Localization uses its own Pending request identifiers independently of page epochs. Mutations never retry automatically; 403 preserves permission feedback, and editor 409 recovery preserves the draft and fetches the latest source.

## Application composition

| Module | Responsibility |
| --- | --- |
| `App.State` | Compose feature Models and wrap feature messages; own navigation, session, generation, localization, and shell state only. |
| `App.Init` | Decode flags, initialize feature state, start session and language loading. |
| `App.Session`, `App.Context`, `App.Feedback` | Define authentication, active language/texts, and application feedback respectively. These contain no aggregate feature state. |
| `App.Routing` | Reset route reads through feature APIs, enter features, wrap load commands, and coordinate unread refreshes. |
| `App.Features` | Map feature commands, apply explicit outcomes, and coordinate navigation, session cleanup, and cross-feature changes. |
| `App.Access` | Apply session-expiry cleanup and clear protected state after logout. |
| `App.Interaction` | Apply a completed like consistently to visible post representations across features. |
| `App.Localization`, `App.Browser` | Coordinate the existing localization state machine and handle incoming browser data. |
| `App.Shell` | Render navigation, loading/fallback UI, drawer, confirmations, language selector, and global feedback around a supplied page. |
| `App.View`, `App.View.*` | Select document titles/pages and provide feature-specific view data, callbacks, and editor slots. |

`App.State` is an application composition root, not a repository for feature types. Features do not import it or Main. Dependencies flow from Main and application adapters to features, then to shared presentation and infrastructure. Features may use narrow `App.Session`, `App.Context`, and `App.Feedback` types; these modules do not depend on application composition or feature modules. Features do not call another feature's update. The compiled module graph is acyclic.

## Feature ownership

| Feature | Owned state and behavior |
| --- | --- |
| `Feature.Auth` | Login/register/verification forms, verification token, authentication requests and outcomes. |
| `Feature.Editor` | Topic/reply/edit modes, drafts, exact source versions, attachments, uploads, saves, and conflict recovery. |
| `Feature.CommunityManage` | Policies, roster offsets, management permissions and requests, moderation fields, and busy actions. |
| `Feature.Profile` | Public/own profile reads, settings form, avatar keep/clear/replace states, uploads and saving. |
| `Feature.Search` | URL-backed search kind/query, result variants, loading, submission and pagination. |
| `Feature.Notifications` | Notification snapshot, unread count, read actions and snapshot cursor. |
| `Feature.Post` | Post/direct/nested reads, expanded replies, likes, deletion and mutation state. |
| `Feature.Feed` | Latest topic page and offset-based loading. |
| `Feature.Community` | Community discovery/details/topics and permission-aware presentation. |
| `Feature.CommunityCreate` | Creation form, policy normalization and creation outcome. |

Auth, Editor, and CommunityManage separate State, Update, and View within their directories. Smaller features stay in single modules. Each owns its local Model/Msg; updates return local state and commands plus semantic outcomes when needed. View configs use callbacks and presentation data. Post receives the reply editor as `Html msg`; the application supplies it from Editor, avoiding a Post/Editor dependency cycle.

## State lifecycle and response boundaries

`App.Routing.loadRoute` resets remote content reads, expanded replies, profile reads, notifications/counts, source/editor and management state. Authentication forms and profile drafts survive this shared reset. Entering NewCommunity resets that form; NewTopic starts a new draft; EditPost waits for source. Notifications, settings, and management only start protected reads for authenticated sessions. There is no new page cache.

`App.Access.clearPrivate` clears own profile/form, notifications/count, management state and all mutation busy keys, preserving the original cleanup boundary. Feature outcomes determine when a 401 invokes this cleanup. Existing profile save/upload and community-creation failures remain local form errors and preserve drafts; they do not independently change authentication state. Route read failures and the existing session-aware action paths retain their original cleanup behavior. See the change's migration checklist and regression evidence for the comparison with the original implementation.

Main wraps asynchronous feature commands with route epochs using `Cmd.map`. Inputs use separate immediate-message wrappers. Only validated responses reach feature decoding/update functions. Successful authentication outcomes update generations, navigate, and request CSRF; post saves/deletes request navigation; notification actions reload their snapshot; completed likes update visible representations through the application adapter.

## Presentation and browser boundary

`Ui.Feedback`, `Ui.Pagination`, `Ui.Formatting`, `Ui.PostCard`, `Ui.CommunityCard`, `Ui.CommunityPolicy`, and `Ui.Layout` accept presentation data and generic callbacks. They own no HTTP state and do not depend on the application Model/Msg. Cards receive nested content through a callback. `Ports.elm` owns port definitions, message decoding and commands for locale, CSRF, formatting, focus and native dialogs, preserving the JavaScript protocol.

Session cookies remain HttpOnly. The JavaScript bootstrap reads only the non-HttpOnly CSRF cookie and sends it back through Elm for mutation headers. The server remains authoritative for permissions, CSRF, and membership. JavaScript is otherwise limited to browser preferences, dynamic catalog decoding, Intl formatting, focus requests, native dialog control, and IME composition protection.

Post display renders the server's sanitized HTML through an allowlisted Elm parser. Editing always uses the source endpoint and sends the exact expected version as a JSON number. The generated local-time display decorates semantic `<time datetime>` elements without changing stored timestamps.

Translations are generated from Fluent catalogs by Travelm Agency. Only selected JSON catalogs load at runtime. See `localization.md` for resource identity and failure behavior.

The responsive shell exposes a top application bar, desktop navigation, a native modal drawer on compact widths, a skip link, and route-focused headings. Shared CSS tokens cover Material color roles, spatial sizing, focus, forced colors, reduced motion, and script-aware font fallback. Native form controls, dialogs, lists, and landmarks are preferred over custom widgets.

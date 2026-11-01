module Route exposing (Route(..), offset, pageUrl, parse, path, query, replyPageUrl)

import Domain
import Url exposing (Url)
import Url.Builder as Builder
import Url.Parser as Parser exposing ((</>), Parser, s, string, top)


type Route
    = Latest
    | Communities
    | Community String
    | Post String
    | NewCommunity
    | NewTopic String
    | EditPost String
    | Login
    | Register
    | Verify
    | Search
    | Notifications
    | Profile String
    | Settings
    | PasswordReset
    | PasswordResetConfirm
    | PasswordSettings
    | AccountContent Domain.AccountContentSource
    | AccountBlocks
    | AdminOverview
    | AdminReports
    | AdminModlog
    | AdminBans
    | AdminSettings
    | Manage String
    | NotFound


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Latest top
        , Parser.map NewCommunity (s "communities" </> s "new")
        , Parser.map NewTopic (s "communities" </> string </> s "new")
        , Parser.map Manage (s "communities" </> string </> s "manage")
        , Parser.map Community (s "communities" </> string)
        , Parser.map Communities (s "communities")
        , Parser.map EditPost (s "posts" </> string </> s "edit")
        , Parser.map Post (s "posts" </> string)
        , Parser.map Login (s "login")
        , Parser.map Register (s "register")
        , Parser.map Verify (s "verify-email")
        , Parser.map Search (s "search")
        , Parser.map Notifications (s "notifications")
        , Parser.map PasswordReset (s "reset-password")
        , Parser.map PasswordResetConfirm (s "reset-password" </> s "confirm")
        , Parser.map PasswordSettings (s "settings" </> s "password")
        , Parser.map (AccountContent Domain.SavedContent) (s "account" </> s "saved")
        , Parser.map (AccountContent Domain.ReadContent) (s "account" </> s "read")
        , Parser.map (AccountContent Domain.HiddenContent) (s "account" </> s "hidden")
        , Parser.map (AccountContent Domain.LikedContent) (s "account" </> s "liked")
        , Parser.map AccountBlocks (s "account" </> s "blocks")
        , Parser.map AdminReports (s "admin" </> s "reports")
        , Parser.map AdminModlog (s "admin" </> s "modlog")
        , Parser.map AdminBans (s "admin" </> s "bans")
        , Parser.map AdminSettings (s "admin" </> s "settings")
        , Parser.map AdminOverview (s "admin")
        , Parser.map Profile (s "profiles" </> string)
        , Parser.map Settings (s "settings" </> s "profile")
        ]


parse : Url -> Route
parse =
    Parser.parse parser >> Maybe.withDefault NotFound


path : Route -> String
path route =
    case route of
        Latest ->
            "/"

        Communities ->
            "/communities"

        Community id ->
            Builder.absolute [ "communities", id ] []

        Post id ->
            Builder.absolute [ "posts", id ] []

        NewCommunity ->
            "/communities/new"

        NewTopic id ->
            Builder.absolute [ "communities", id, "new" ] []

        EditPost id ->
            Builder.absolute [ "posts", id, "edit" ] []

        Login ->
            "/login"

        Register ->
            "/register"

        Verify ->
            "/verify-email"

        Search ->
            "/search"

        Notifications ->
            "/notifications"

        Profile name ->
            Builder.absolute [ "profiles", name ] []

        Settings ->
            "/settings/profile"

        PasswordReset ->
            "/reset-password"

        PasswordResetConfirm ->
            "/reset-password/confirm"

        PasswordSettings ->
            "/settings/password"

        AccountContent source ->
            "/account/"
                ++ (case source of
                        Domain.SavedContent ->
                            "saved"

                        Domain.ReadContent ->
                            "read"

                        Domain.HiddenContent ->
                            "hidden"

                        Domain.LikedContent ->
                            "liked"
                   )

        AccountBlocks ->
            "/account/blocks"

        AdminOverview ->
            "/admin"

        AdminReports ->
            "/admin/reports"

        AdminModlog ->
            "/admin/modlog"

        AdminBans ->
            "/admin/bans"

        AdminSettings ->
            "/admin/settings"

        Manage id ->
            Builder.absolute [ "communities", id, "manage" ] []

        NotFound ->
            "/404"


query : String -> Url -> String
query name url =
    url.query
        |> Maybe.withDefault ""
        |> String.split "&"
        |> List.filterMap
            (\part ->
                case String.split "=" part of
                    key :: values ->
                        if key == name then
                            Just (Url.percentDecode (String.replace "+" " " (String.join "=" values)) |> Maybe.withDefault "")

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.head
        |> Maybe.withDefault ""


offset : Url -> Int
offset url =
    query "offset" url |> String.toInt |> Maybe.withDefault 0 |> max 0


pageUrl : Url -> Int -> String
pageUrl url value =
    url.path
        ++ Builder.toQuery
            ([ Builder.int "offset" (max 0 value) ]
                ++ (if parse url == Search then
                        [ Builder.string "q" (query "q" url), Builder.string "kind" (query "kind" url) ]

                    else
                        []
                   )
            )


replyPageUrl : Url -> String -> Int -> Int -> String
replyPageUrl url sort depth offsetValue =
    url.path
        ++ Builder.toQuery
            [ Builder.int "offset" (max 0 offsetValue)
            , Builder.string "sort" sort
            , Builder.int "max_depth" (clamp 1 8 depth)
            ]

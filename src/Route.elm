module Route exposing (Route(..), offset, pageUrl, parse, path, query)

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

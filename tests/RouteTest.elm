module RouteTest exposing (suite)

import Expect
import Route
import Test exposing (Test, describe, test)
import Url


parse : String -> Route.Route
parse value =
    Url.fromString ("https://forum.test" ++ value)
        |> Maybe.map Route.parse
        |> Maybe.withDefault Route.NotFound


suite : Test
suite =
    describe "application routes"
        [ test "parses stable collection and object routes" <|
            \_ ->
                Expect.equal
                    [ Route.Latest
                    , Route.Communities
                    , Route.Community "c1"
                    , Route.Post "p1"
                    , Route.EditPost "p1"
                    , Route.Notifications
                    , Route.Manage "c1"
                    ]
                    (List.map parse [ "/", "/communities", "/communities/c1", "/posts/p1", "/posts/p1/edit", "/notifications", "/communities/c1/manage" ])
        , test "keeps search query and pagination" <|
            \_ ->
                let
                    url =
                        Url.fromString "https://forum.test/search?kind=posts&q=%E4%B8%AD%E6%96%87&offset=40"
                in
                Expect.equal ( "posts", "中文", 40 )
                    (url |> Maybe.map (\value -> ( Route.query "kind" value, Route.query "q" value, Route.offset value )) |> Maybe.withDefault ( "", "", -1 ))
        , test "builds page URLs without losing search context" <|
            \_ ->
                Url.fromString "https://forum.test/search?kind=communities&q=news&offset=20"
                    |> Maybe.map (\url -> Route.pageUrl url 40 == "/search?offset=40&q=news&kind=communities")
                    |> Maybe.withDefault False
                    |> Expect.equal True
        ]

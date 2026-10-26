module DomainTest exposing (suite)

import Domain
import Expect
import Json.Decode as Decode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "backend DTO decoding"
        [ test "decodes a notification page with numeric ids" <|
            \_ ->
                let
                    json =
                        "{\"items\":[{\"id\":1,\"kind\":\"reply\",\"post_id\":\"p1\",\"actor_uri\":\"https://forum.test/users/bob\",\"created_at\":\"2026-10-20T08:30:00Z\",\"read\":false}],\"limit\":20,\"offset\":0,\"through_cursor\":\"2026-10-20T08:30:00Z|1\"}"
                in
                Expect.equal (Ok 1) (Decode.decodeString Domain.notificationPage json |> Result.map (.items >> List.length))
        , test "decodes nested author and falls back to the Actor URI" <|
            \_ ->
                let
                    payload extra =
                        "{\"id\":\"p1\",\"community_id\":\"c1\",\"object_type\":\"Page\",\"title\":\"T\",\"body\":\"B\",\"body_html\":\"<p>B</p>\",\"author_actor_uri\":\"https://a.test/users/a\","
                            ++ extra
                            ++ "\"authored_at\":\"2026-10-20T08:30:00Z\",\"version\":4,\"content_format\":\"markdown\",\"like_count\":0,\"liked_by_me\":false,\"reply_count\":0,\"deleted\":false,\"permissions\":{\"can_edit\":false,\"can_delete\":false,\"can_like\":true,\"can_reply\":true,\"can_hide\":false,\"can_moderate\":false},\"attachments\":[]}"
                in
                Expect.equal [ Ok ( "alice@a.test", "Alice" ), Ok ( "", "" ) ]
                    [ Decode.decodeString Domain.post (payload "\"author\":{\"acct\":\"alice@a.test\",\"display_name\":\"Alice\"},") |> Result.map (\post -> ( post.author.acct, post.author.displayName ))
                    , Decode.decodeString Domain.post (payload "") |> Result.map (\post -> ( post.author.acct, post.author.displayName ))
                    ]
        , test "accepts numeric and string post revisions" <|
            \_ ->
                let
                    fragment revision =
                        "{\"id\":\"p1\",\"community_id\":\"c1\",\"object_type\":\"Page\",\"title\":\"T\",\"body\":\"B\",\"body_html\":\"<p>B</p>\",\"author_actor_uri\":\"https://a.test/users/a\",\"authored_at\":\"2026-10-20T08:30:00Z\",\"version\":"
                            ++ revision
                            ++ ",\"content_format\":\"markdown\",\"like_count\":0,\"liked_by_me\":false,\"reply_count\":0,\"deleted\":false,\"permissions\":{\"can_edit\":false,\"can_delete\":false,\"can_like\":true,\"can_reply\":true,\"can_hide\":false,\"can_moderate\":false},\"attachments\":[]}"
                in
                Expect.equal [ Ok "4", Ok "9223372036854775807" ]
                    [ Decode.decodeString Domain.post (fragment "4") |> Result.map .version
                    , Decode.decodeString Domain.post (fragment "\"9223372036854775807\"") |> Result.map .version
                    ]
        , test "decodes media and profile responses" <|
            \_ ->
                let
                    media =
                        "{\"id\":\"u1\",\"purpose\":\"post\",\"media_type\":\"image/png\",\"size\":4,\"name\":\"pixel.png\",\"reference\":\"/api/v1/media/u1\"}"

                    profile =
                        "{\"actor_uri\":\"https://a.test/users/alice\",\"username\":\"alice\",\"display_name\":\"Alice\",\"biography\":\"Bio\",\"biography_html\":\"<p>Bio</p>\",\"avatar_url\":\"\",\"updated_at\":\"2026-10-20T08:30:00Z\"}"
                in
                Expect.equal [ Ok "4", Ok "alice" ]
                    [ Decode.decodeString Domain.media media |> Result.map .size
                    , Decode.decodeString Domain.profile profile |> Result.map .username
                    ]
        ]

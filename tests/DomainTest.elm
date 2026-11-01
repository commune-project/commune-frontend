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
        , test "decodes additive post state and recursive children" <|
            \_ ->
                let
                    reply id children =
                        "{\"id\":\""
                            ++ id
                            ++ "\",\"community_id\":\"c1\",\"object_type\":\"Note\",\"body\":\"B\",\"body_html\":\"<p>B</p>\",\"author_actor_uri\":\"https://a.test/users/a\",\"authored_at\":\"2026-10-20T08:30:00Z\",\"version\":1,\"content_format\":\"markdown\",\"like_count\":1,\"liked_by_me\":true,\"score\":1,\"upvotes\":1,\"downvotes\":0,\"voted_by_me\":1,\"saved_by_me\":true,\"read_by_me\":true,\"hidden_by_me\":false,\"reply_count\":"
                            ++ String.fromInt (List.length children)
                            ++ ",\"deleted\":false,\"permissions\":{\"can_edit\":false,\"can_delete\":false,\"can_like\":true,\"can_vote\":true,\"can_upvote\":true,\"can_downvote\":true,\"can_reply\":true,\"can_hide\":false,\"can_save\":true,\"can_hide_for_me\":true,\"can_moderate\":false},\"attachments\":[],\"children\":["
                            ++ String.join "," children
                            ++ "],\"depth\":1,\"child_count\":"
                            ++ String.fromInt (List.length children)
                            ++ "}"
                in
                Expect.equal (Ok ( 1, 1, [ "r2" ] ))
                    (Decode.decodeString Domain.threadedPost (reply "r1" [ reply "r2" [] ])
                        |> Result.map
                            (\(Domain.ThreadedPost node) ->
                                ( node.post.votedByMe
                                , node.post.upvotes
                                , List.map
                                    (\(Domain.ThreadedPost child) -> child.post.id)
                                    node.children
                                )
                            )
                    )
        , test "decodes community follow state" <|
            \_ ->
                let
                    payload =
                        "{\"id\":\"c1\",\"name\":\"news\",\"title\":\"News\",\"description\":\"\",\"federation_mode\":\"federated\",\"read_policy\":\"eligible_users\",\"post_policy\":\"eligible_users\",\"follow_policy\":\"approval\",\"follower_count\":7,\"host_site_id\":\"a\",\"viewer\":{\"is_member\":false,\"is_creator\":false,\"is_manager\":false,\"is_following\":false,\"follow_state\":\"pending\",\"can_follow\":false},\"permissions\":{\"can_post\":false,\"can_manage\":false,\"can_manage_members\":false,\"can_manage_managers\":false}}"
                in
                Expect.equal (Ok ( "approval", 7, "pending" ))
                    (Decode.decodeString Domain.community payload
                        |> Result.map (\community -> ( community.followPolicy, community.followerCount, community.followState ))
                    )
        , test "decodes notification targets and management DTOs" <|
            \_ ->
                let
                    notification =
                        "{\"id\":9,\"kind\":\"report\",\"post_id\":\"\",\"target_kind\":\"report\",\"target_id\":\"42\",\"actor_uri\":\"https://a.test/users/a\",\"created_at\":\"2026-10-20T08:30:00Z\",\"read\":false}"

                    report =
                        "{\"id\":42,\"target_kind\":\"post\",\"target_id\":\"p1\",\"reason\":\"spam\",\"state\":\"open\",\"resolution_note\":\"\",\"created_at\":\"2026-10-20T08:30:00Z\"}"

                    modlog =
                        "{\"id\":3,\"action\":\"ban-site\",\"actor_actor_uri\":\"https://a.test/users/admin\",\"target_kind\":\"person\",\"target_id\":\"https://b.test/users/b\",\"reason\":\"spam\",\"created_at\":\"2026-10-20T08:30:00Z\"}"

                    block =
                        "{\"kind\":\"instance\",\"target\":\"b.test\",\"created_at\":\"2026-10-20T08:30:00Z\"}"

                    followRequest =
                        "{\"actor_uri\":\"https://a.test/users/a\",\"updated_at\":\"2026-10-20T08:30:00Z\"}"
                in
                Expect.equal [ Ok "report:42", Ok "spam", Ok "ban-site", Ok "b.test", Ok "https://a.test/users/a" ]
                    [ Decode.decodeString Domain.notice notification |> Result.map (\notice -> notice.targetKind ++ ":" ++ notice.targetId)
                    , Decode.decodeString Domain.report report |> Result.map .reason
                    , Decode.decodeString Domain.moderationLogEntry modlog |> Result.map .action
                    , Decode.decodeString Domain.accountBlock block |> Result.map .target
                    , Decode.decodeString Domain.followRequest followRequest |> Result.map .actor
                    ]
        , test "decodes site vote settings and account content sources" <|
            \_ ->
                Expect.all
                    [ \_ ->
                        Expect.equal (Ok ( True, False ))
                            (Decode.decodeString Domain.voteSettings "{\"upvotes_enabled\":true,\"downvotes_enabled\":false}" |> Result.map (\settings -> ( settings.upvotesEnabled, settings.downvotesEnabled )))
                    , \_ ->
                        Expect.equal [ Just "saved", Just "liked", Nothing ]
                            [ Domain.accountContentSource "saved" |> Maybe.map (always "saved")
                            , Domain.accountContentSource "liked" |> Maybe.map (always "liked")
                            , Domain.accountContentSource "unknown" |> Maybe.map (always "unknown")
                            ]
                    ]
                    ()
        ]

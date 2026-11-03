module Domain exposing (AccountBlock, AccountContentSource(..), Attachment, Author, Community, FollowRequest, Identity, MediaUpload, MentionCandidate, ModerationLogEntry, Notice, NotificationPage, Page, Post, Profile, Report, Roster, Source, ThreadedPost(..), VoteSettings, accountBlock, accountContentSource, community, followRequest, identity, media, mentionCandidate, mentionCandidatePage, moderationLogEntry, notice, notificationPage, page, post, profile, report, roster, source, threadedPost, voteSettings)

import Dict
import Json.Decode as D exposing (Decoder)


type alias Page a =
    { items : List a, limit : Int, offset : Int }


type alias Identity =
    { username : String
    , actor : String
    , siteId : String
    , accountId : String
    , siteAdmin : Bool
    , deploymentAdmin : Bool
    }


type alias Community =
    { id : String
    , name : String
    , title : String
    , description : String
    , mode : String
    , readPolicy : String
    , postPolicy : String
    , followPolicy : String
    , followerCount : Int
    , host : String
    , member : Bool
    , creator : Bool
    , manager : Bool
    , following : Bool
    , followState : String
    , canFollow : Bool
    , canPost : Bool
    , canManage : Bool
    , canMembers : Bool
    , canManagers : Bool
    }


type alias Attachment =
    { url : String, name : String, mediaType : String, preview : String }


type alias Author =
    { acct : String, displayName : String }


type alias Post =
    { id : String
    , community : String
    , title : String
    , body : String
    , html : String
    , authorActor : String
    , author : Author
    , parent : String
    , date : String
    , version : String
    , format : String
    , likes : Int
    , liked : Bool
    , score : Int
    , upvotes : Int
    , downvotes : Int
    , votedByMe : Int
    , saved : Bool
    , read : Bool
    , hiddenByMe : Bool
    , replies : Int
    , deleted : Bool
    , canEdit : Bool
    , canDelete : Bool
    , canLike : Bool
    , canVote : Bool
    , canUpvote : Bool
    , canDownvote : Bool
    , canReply : Bool
    , canHide : Bool
    , canSave : Bool
    , canHideForMe : Bool
    , canModerate : Bool
    , attachments : List Attachment
    }


type ThreadedPost
    = ThreadedPost
        { post : Post
        , children : List ThreadedPost
        , depth : Int
        , childCount : Int
        }


type alias Source =
    { id : String, title : String, body : String, format : String, version : String, attachments : List String }


type alias Profile =
    { username : String, actor : String, name : String, biography : String, html : String, avatar : String }


type alias MentionCandidate =
    { actor : String, acct : String, displayName : String, avatar : String }


type alias Roster =
    { actor : String, creator : Bool, manager : Bool }


type alias Notice =
    { id : String
    , kind : String
    , post : String
    , targetKind : String
    , targetId : String
    , actor : String
    , date : String
    , read : Bool
    }


type alias NotificationPage =
    { items : List Notice
    , limit : Int
    , offset : Int
    , cursor : String
    }


type alias MediaUpload =
    { id : String
    , purpose : String
    , mediaType : String
    , size : String
    , name : String
    , reference : String
    , preview : String
    }


type alias VoteSettings =
    { upvotesEnabled : Bool, downvotesEnabled : Bool }


type alias Report =
    { id : String
    , targetKind : String
    , targetId : String
    , communityId : String
    , reason : String
    , state : String
    , resolutionNote : String
    , createdAt : String
    }


type alias ModerationLogEntry =
    { id : String
    , communityId : String
    , action : String
    , actorActorUri : String
    , targetKind : String
    , targetId : String
    , reason : String
    , createdAt : String
    }


type alias AccountBlock =
    { kind : String
    , target : String
    , createdAt : String
    }


type alias FollowRequest =
    { actor : String, updatedAt : String }


type AccountContentSource
    = SavedContent
    | ReadContent
    | HiddenContent
    | LikedContent


and : Decoder a -> Decoder (a -> b) -> Decoder b
and =
    D.map2 (|>)


optional : String -> Decoder a -> a -> Decoder a
optional name decoder fallback =
    D.dict D.value
        |> D.andThen
            (\fields ->
                case Dict.get name fields of
                    Nothing ->
                        D.succeed fallback

                    Just value ->
                        case D.decodeValue decoder value of
                            Ok result ->
                                D.succeed result

                            Err error ->
                                D.fail (D.errorToString error)
            )


page : Decoder a -> Decoder (Page a)
page item =
    D.map3 Page (D.field "items" (D.list item)) (D.field "limit" D.int) (D.field "offset" D.int)


identity : Decoder Identity
identity =
    D.succeed Identity
        |> and (D.field "username" D.string)
        |> and (D.field "actor_uri" D.string)
        |> and (optional "site_id" D.string "")
        |> and (optional "account_id" identifier "")
        |> and (D.at [ "roles", "site_administrator" ] D.bool)
        |> and (D.at [ "roles", "deployment_superadministrator" ] D.bool)


community : Decoder Community
community =
    D.succeed Community
        |> and (D.field "id" D.string)
        |> and (D.field "name" D.string)
        |> and (D.field "title" D.string)
        |> and (D.field "description" D.string)
        |> and (D.field "federation_mode" D.string)
        |> and (D.field "read_policy" D.string)
        |> and (D.field "post_policy" D.string)
        |> and (optional "follow_policy" D.string "open")
        |> and (optional "follower_count" D.int 0)
        |> and (D.field "host_site_id" D.string)
        |> and (D.at [ "viewer", "is_member" ] D.bool)
        |> and (D.at [ "viewer", "is_creator" ] D.bool)
        |> and (D.at [ "viewer", "is_manager" ] D.bool)
        |> and (D.oneOf [ D.at [ "viewer", "is_following" ] D.bool, D.succeed False ])
        |> and (D.oneOf [ D.at [ "viewer", "follow_state" ] D.string, D.succeed "none" ])
        |> and (D.oneOf [ D.at [ "viewer", "can_follow" ] D.bool, D.succeed False ])
        |> and (D.at [ "permissions", "can_post" ] D.bool)
        |> and (D.at [ "permissions", "can_manage" ] D.bool)
        |> and (D.at [ "permissions", "can_manage_members" ] D.bool)
        |> and (D.at [ "permissions", "can_manage_managers" ] D.bool)


post : Decoder Post
post =
    D.succeed Post
        |> and (D.field "id" D.string)
        |> and (D.field "community_id" D.string)
        |> and (optional "title" D.string "")
        |> and (D.field "body" D.string)
        |> and (D.field "body_html" D.string)
        |> and (D.field "author_actor_uri" D.string)
        |> and (optional "author" authorDecoder (Author "" ""))
        |> and (optional "parent_id" D.string "")
        |> and (D.field "authored_at" D.string)
        |> and (D.field "version" revision)
        |> and (D.field "content_format" D.string)
        |> and (D.field "like_count" D.int)
        |> and (D.field "liked_by_me" D.bool)
        |> and (optional "score" D.int 0)
        |> and (optional "upvotes" D.int 0)
        |> and (optional "downvotes" D.int 0)
        |> and (optional "voted_by_me" D.int 0)
        |> and (optional "saved_by_me" D.bool False)
        |> and (optional "read_by_me" D.bool False)
        |> and (optional "hidden_by_me" D.bool False)
        |> and (D.field "reply_count" D.int)
        |> and (D.field "deleted" D.bool)
        |> and (D.at [ "permissions", "can_edit" ] D.bool)
        |> and (D.at [ "permissions", "can_delete" ] D.bool)
        |> and (D.at [ "permissions", "can_like" ] D.bool)
        |> and (D.oneOf [ D.at [ "permissions", "can_vote" ] D.bool, D.succeed False ])
        |> and (D.oneOf [ D.at [ "permissions", "can_upvote" ] D.bool, D.succeed False ])
        |> and (D.oneOf [ D.at [ "permissions", "can_downvote" ] D.bool, D.succeed False ])
        |> and (D.at [ "permissions", "can_reply" ] D.bool)
        |> and (D.at [ "permissions", "can_hide" ] D.bool)
        |> and (D.oneOf [ D.at [ "permissions", "can_save" ] D.bool, D.succeed False ])
        |> and (D.oneOf [ D.at [ "permissions", "can_hide_for_me" ] D.bool, D.succeed False ])
        |> and (D.at [ "permissions", "can_moderate" ] D.bool)
        |> and (D.field "attachments" (D.list attachment))


threadedPost : Decoder ThreadedPost
threadedPost =
    D.map4
        (\postValue children depth childCount ->
            ThreadedPost
                { post = postValue
                , children = children
                , depth = depth
                , childCount = childCount
                }
        )
        post
        (D.oneOf
            [ D.field "children" (D.lazy (\_ -> D.list threadedPost))
            , D.succeed []
            ]
        )
        (optional "depth" D.int 1)
        (optional "child_count" D.int 0)


revision : Decoder String
revision =
    D.oneOf
        [ D.string |> D.andThen validateRevision
        , D.int |> D.map String.fromInt |> D.andThen validateRevision
        ]


validateRevision : String -> Decoder String
validateRevision value =
    if value /= "" && not (String.startsWith "0" value) && String.all Char.isDigit value && String.length value <= 19 && (String.length value < 19 || value <= "9223372036854775807") then
        D.succeed value

    else
        D.fail "Expected a positive signed 64-bit revision"


authorDecoder : Decoder Author
authorDecoder =
    D.map2 Author
        (optional "acct" D.string "")
        (optional "display_name" D.string "")


attachment : Decoder Attachment
attachment =
    D.map4 Attachment
        (D.field "url" D.string)
        (optional "name" D.string "")
        (D.field "media_type" D.string)
        (optional "preview_url" D.string "")


source : Decoder Source
source =
    D.map6 Source (D.field "id" D.string) (D.field "title" D.string) (D.field "body" D.string) (D.field "content_format" D.string) (D.field "version" revision) (D.field "attachment_ids" (D.list D.string))


profile : Decoder Profile
profile =
    D.map6 Profile (D.field "username" D.string) (D.field "actor_uri" D.string) (D.field "display_name" D.string) (D.field "biography" D.string) (D.field "biography_html" D.string) (D.field "avatar_url" D.string)


mentionCandidate : Decoder MentionCandidate
mentionCandidate =
    D.map4 MentionCandidate
        (D.field "actor_uri" D.string)
        (D.field "acct" D.string)
        (optional "display_name" D.string "")
        (optional "avatar" D.string "")


mentionCandidatePage : Decoder (List MentionCandidate)
mentionCandidatePage =
    D.field "items" (D.list mentionCandidate)


roster : Decoder Roster
roster =
    D.map3 Roster (D.field "actor_uri" D.string) (D.field "is_creator" D.bool) (D.field "is_manager" D.bool)


notice : Decoder Notice
notice =
    D.succeed Notice
        |> and (D.field "id" identifier)
        |> and (D.field "kind" D.string)
        |> and (optional "post_id" D.string "")
        |> and (optional "target_kind" D.string "post")
        |> and (optional "target_id" identifier "")
        |> and (D.field "actor_uri" D.string)
        |> and (D.field "created_at" D.string)
        |> and (D.field "read" D.bool)


identifier : Decoder String
identifier =
    D.oneOf [ D.string, D.int |> D.map String.fromInt ]


notificationPage : Decoder NotificationPage
notificationPage =
    D.map4 NotificationPage
        (D.field "items" (D.list notice))
        (D.field "limit" D.int)
        (D.field "offset" D.int)
        (D.field "through_cursor" D.string)


media : Decoder MediaUpload
media =
    D.map7 MediaUpload
        (D.field "id" D.string)
        (D.field "purpose" D.string)
        (D.field "media_type" D.string)
        (D.field "size" size)
        (D.field "name" D.string)
        (D.field "reference" D.string)
        (optional "preview_url" D.string "")


size : Decoder String
size =
    D.oneOf [ D.string, D.int |> D.map String.fromInt ]


voteSettings : Decoder VoteSettings
voteSettings =
    D.map2 VoteSettings
        (D.field "upvotes_enabled" D.bool)
        (D.field "downvotes_enabled" D.bool)


report : Decoder Report
report =
    D.map8 Report
        (D.field "id" identifier)
        (D.field "target_kind" D.string)
        (D.field "target_id" D.string)
        (optional "community_id" D.string "")
        (D.field "reason" D.string)
        (D.field "state" D.string)
        (optional "resolution_note" D.string "")
        (D.field "created_at" D.string)


moderationLogEntry : Decoder ModerationLogEntry
moderationLogEntry =
    D.map8 ModerationLogEntry
        (D.field "id" identifier)
        (optional "community_id" D.string "")
        (D.field "action" D.string)
        (D.field "actor_actor_uri" D.string)
        (D.field "target_kind" D.string)
        (D.field "target_id" D.string)
        (optional "reason" D.string "")
        (D.field "created_at" D.string)


accountBlock : Decoder AccountBlock
accountBlock =
    D.map3 AccountBlock
        (D.field "kind" D.string)
        (D.field "target" D.string)
        (D.field "created_at" D.string)


followRequest : Decoder FollowRequest
followRequest =
    D.map2 FollowRequest
        (D.field "actor_uri" D.string)
        (D.field "updated_at" D.string)


accountContentSource : String -> Maybe AccountContentSource
accountContentSource value =
    case value of
        "saved" ->
            Just SavedContent

        "read" ->
            Just ReadContent

        "hidden" ->
            Just HiddenContent

        "liked" ->
            Just LikedContent

        _ ->
            Nothing

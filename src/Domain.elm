module Domain exposing (Attachment, Author, Community, Identity, MediaUpload, Notice, NotificationPage, Page, Post, Profile, Roster, Source, community, identity, media, notice, notificationPage, page, post, profile, roster, source)

import Dict
import Json.Decode as D exposing (Decoder)


type alias Page a =
    { items : List a, limit : Int, offset : Int }


type alias Identity =
    { username : String, actor : String, siteAdmin : Bool, deploymentAdmin : Bool }


type alias Community =
    { id : String
    , name : String
    , title : String
    , description : String
    , mode : String
    , readPolicy : String
    , postPolicy : String
    , host : String
    , member : Bool
    , creator : Bool
    , manager : Bool
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
    , replies : Int
    , deleted : Bool
    , canEdit : Bool
    , canDelete : Bool
    , canLike : Bool
    , canReply : Bool
    , canHide : Bool
    , canModerate : Bool
    , attachments : List Attachment
    }


type alias Source =
    { id : String, title : String, body : String, format : String, version : String, attachments : List String }


type alias Profile =
    { username : String, actor : String, name : String, biography : String, html : String, avatar : String }


type alias Roster =
    { actor : String, creator : Bool, manager : Bool }


type alias Notice =
    { id : String, kind : String, post : String, actor : String, date : String, read : Bool }


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
    D.map4 Identity
        (D.field "username" D.string)
        (D.field "actor_uri" D.string)
        (D.at [ "roles", "site_administrator" ] D.bool)
        (D.at [ "roles", "deployment_superadministrator" ] D.bool)


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
        |> and (D.field "host_site_id" D.string)
        |> and (D.at [ "viewer", "is_member" ] D.bool)
        |> and (D.at [ "viewer", "is_creator" ] D.bool)
        |> and (D.at [ "viewer", "is_manager" ] D.bool)
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
        |> and (D.field "reply_count" D.int)
        |> and (D.field "deleted" D.bool)
        |> and (D.at [ "permissions", "can_edit" ] D.bool)
        |> and (D.at [ "permissions", "can_delete" ] D.bool)
        |> and (D.at [ "permissions", "can_like" ] D.bool)
        |> and (D.at [ "permissions", "can_reply" ] D.bool)
        |> and (D.at [ "permissions", "can_hide" ] D.bool)
        |> and (D.at [ "permissions", "can_moderate" ] D.bool)
        |> and (D.field "attachments" (D.list attachment))


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


roster : Decoder Roster
roster =
    D.map3 Roster (D.field "actor_uri" D.string) (D.field "is_creator" D.bool) (D.field "is_manager" D.bool)


notice : Decoder Notice
notice =
    D.map6 Notice (D.field "id" identifier) (D.field "kind" D.string) (D.field "post_id" D.string) (D.field "actor_uri" D.string) (D.field "created_at" D.string) (D.field "read" D.bool)


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


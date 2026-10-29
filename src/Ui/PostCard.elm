module Ui.PostCard exposing (Config, deleteTriggerId, postCard, viewAttachments)

import Domain
import Generated.I18n as Translations
import Html exposing (Html, a, article, bdi, button, div, h2, h3, li, p, section, span, text, time, ul)
import Html.Attributes as A
import Html.Events as Events
import List
import Route
import Ui.Formatting exposing (Formatting, boolText, formattedCount, formattedDate, likesLabel, repliesLabel)
import Ui.Icon
import Ui.Rich


type alias Config msg =
    { formatted : Maybe Formatting
    , isBusy : String -> Bool
    , isExpanded : String -> Bool
    , onLike : String -> Bool -> msg
    , onDelete : String -> msg
    , onReplies : String -> msg
    , nested : String -> Html msg
    }


postCard : Config msg -> Translations.I18n -> Domain.Post -> Html msg
postCard config texts post =
    let
        authorText =
            if not (String.isEmpty post.author.displayName) && not (String.isEmpty post.author.acct) then
                post.author.displayName ++ " (@" ++ post.author.acct ++ ")"

            else if not (String.isEmpty post.author.displayName) then
                post.author.displayName

            else if not (String.isEmpty post.author.acct) then
                "@" ++ post.author.acct

            else
                post.authorActor

        likeName =
            (if post.liked then
                Translations.unlikeAction texts

             else
                Translations.likeAction texts
            )
                ++ " · "
                ++ likesLabel config.formatted texts post.likes

        replyName =
            repliesLabel config.formatted texts post.replies
    in
    article [ A.class "card post-card", A.attribute "aria-labelledby" ("post-" ++ post.id) ]
        [ h2 [ A.id ("post-" ++ post.id), A.dir "auto" ]
            [ a [ A.href (Route.path (Route.Post post.id)) ]
                [ text
                    (if String.isEmpty post.title then
                        Translations.repliesTitle texts

                     else
                        post.title
                    )
                ]
            ]
        , p [ A.class "metadata" ]
            [ bdi [] [ text (Translations.authorLabel authorText texts) ]
            , text " · "
            , time [ A.datetime post.date, A.attribute "data-commune-time" "" ] [ text (formattedDate config.formatted post.date) ]
            ]
        , Ui.Rich.view post.html
        , viewAttachments texts post.attachments
        , div [ A.class "post-actions" ]
            [ button
                [ A.class "icon-button"
                , A.attribute "aria-label" likeName
                , A.attribute "title" likeName
                , A.attribute "aria-pressed" (boolText post.liked)
                , A.disabled (not post.canLike || config.isBusy post.id)
                , Events.onClick (config.onLike post.id post.liked)
                ]
                [ Ui.Icon.view (Ui.Icon.Like post.liked)
                , span [ A.class "action-count" ] [ text (formattedCount config.formatted post.likes) ]
                ]
            , if post.canEdit then
                a
                    [ A.class "icon-button"
                    , A.href (Route.path (Route.EditPost post.id))
                    , A.attribute "aria-label" (Translations.editPost texts)
                    , A.attribute "title" (Translations.editPost texts)
                    ]
                    [ Ui.Icon.view Ui.Icon.Edit ]

              else
                text ""
            , if post.canDelete then
                button
                    [ A.id (deleteTriggerId post.id)
                    , A.class "icon-button danger-text"
                    , A.attribute "aria-label" (Translations.deletePost texts)
                    , A.attribute "title" (Translations.deletePost texts)
                    , Events.onClick (config.onDelete post.id)
                    ]
                    [ Ui.Icon.view Ui.Icon.Delete ]

              else
                text ""
            , if post.replies > 0 then
                button
                    [ A.class "icon-button"
                    , A.attribute "aria-label" replyName
                    , A.attribute "title" replyName
                    , A.attribute "aria-expanded" (boolText (config.isExpanded post.id))
                    , Events.onClick (config.onReplies post.id)
                    ]
                    [ Ui.Icon.view Ui.Icon.Reply
                    , span [ A.class "action-count" ] [ text (formattedCount config.formatted post.replies) ]
                    ]

              else
                text ""
            ]
        , if config.isExpanded post.id then
            config.nested post.id

          else
            text ""
        ]


viewAttachments : Translations.I18n -> List Domain.Attachment -> Html msg
viewAttachments texts attachments =
    if List.isEmpty attachments then
        text ""

    else
        section [ A.class "attachments" ]
            [ h3 [] [ text (Translations.attachments texts) ]
            , ul []
                (List.map
                    (\attachment ->
                        li []
                            [ a [ A.href attachment.url, A.rel "noopener noreferrer" ]
                                [ text
                                    (if String.isEmpty attachment.name then
                                        attachment.mediaType

                                     else
                                        attachment.name
                                    )
                                ]
                            ]
                    )
                    attachments
                )
            ]


deleteTriggerId : String -> String
deleteTriggerId id =
    "delete-post-" ++ id

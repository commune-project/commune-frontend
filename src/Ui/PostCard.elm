module Ui.PostCard exposing (Config, deleteTriggerId, postCard, viewAttachments)

import Domain
import Generated.I18n as Translations
import Html exposing (Html, a, article, bdi, button, div, h2, h3, li, p, section, text, time, ul)
import Html.Attributes as A
import Html.Events as Events
import List
import Route
import Ui.Formatting exposing (Formatting, boolText, formattedDate, likesLabel, repliesLabel)
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
                [ A.class "text-button"
                , A.disabled (not post.canLike || config.isBusy post.id)
                , Events.onClick (config.onLike post.id post.liked)
                ]
                [ text
                    ((if post.liked then
                        Translations.unlikeAction texts

                      else
                        Translations.likeAction texts
                     )
                        ++ " · "
                        ++ likesLabel config.formatted texts post.likes
                    )
                ]
            , if post.canEdit then
                a [ A.class "text-button", A.href (Route.path (Route.EditPost post.id)) ]
                    [ text (Translations.editPost texts) ]

              else
                text ""
            , if post.canDelete then
                button
                    [ A.id (deleteTriggerId post.id)
                    , A.class "text-button danger-text"
                    , Events.onClick (config.onDelete post.id)
                    ]
                    [ text (Translations.deletePost texts) ]

              else
                text ""
            , if post.replies > 0 then
                button [ A.class "text-button", Events.onClick (config.onReplies post.id), A.attribute "aria-expanded" (boolText (config.isExpanded post.id)) ]
                    [ text (repliesLabel config.formatted texts post.replies) ]

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

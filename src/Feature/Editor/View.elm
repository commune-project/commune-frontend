module Feature.Editor.View exposing (Config, pageEditor, viewEditor)

import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Feature.Editor.State exposing (..)
import File exposing (File)
import Generated.I18n as Translations
import Html exposing (Html, button, div, form, h3, input, label, li, option, p, pre, section, select, text, textarea, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import List
import Ui.Feedback exposing (loginRequired, problemText, viewRemote)
import Ui.Layout exposing (pageHeading)


type alias Config msg =
    { auth : AuthState
    , retry : msg
    , editorTitleChanged : String -> msg
    , editorBodyChanged : String -> msg
    , editorFormatChanged : String -> msg
    , editorRemoveAttachment : String -> msg
    , editorFileSelected : Maybe File -> msg
    , editorSubmit : msg
    , editorUseLatest : msg
    , editorKeepDraft : msg
    }


pageEditor : Config msg -> Model -> Active -> EditorMode -> Html msg
pageEditor config model active mode =
    let
        title =
            case mode of
                CreateTopic _ ->
                    Translations.publishTopic active.texts

                CreateReply _ ->
                    Translations.publishReply active.texts

                EditPost _ ->
                    Translations.editPost active.texts
    in
    pageHeading title
        (case config.auth of
            Authenticated _ ->
                section [ A.class "primary-column" ]
                    [ case model.editor of
                        Just editor ->
                            viewEditor config active editor

                        Nothing ->
                            viewRemote config.retry
                                active.texts
                                model.source
                                (\_ -> p [ A.class "muted" ] [ text (Translations.loadingMessage active.texts) ])
                    ]

            _ ->
                loginRequired active.texts
        )


viewEditor : Config msg -> Active -> EditorState -> Html msg
viewEditor config active editor =
    form [ Events.onSubmit config.editorSubmit, A.class "card form-stack" ]
        [ case editor.mode of
            CreateReply _ ->
                text ""

            EditPost _ ->
                if String.isEmpty editor.title then
                    text ""

                else
                    editorTitle config active editor

            CreateTopic _ ->
                editorTitle config active editor
        , div []
            [ label [ A.for "editor-body" ] [ text (Translations.topicBody active.texts) ]
            , textarea
                [ A.id "editor-body"
                , A.value editor.body
                , A.dir "auto"
                , A.required True
                , A.attribute "aria-describedby" "editor-help"
                , Events.onInput config.editorBodyChanged
                ]
                []
            , p [ A.id "editor-help", A.class "muted" ] [ text (Translations.topicBodyHelp active.texts) ]
            ]
        , div []
            [ label [ A.for "editor-format" ] [ text (Translations.contentFormat active.texts) ]
            , select [ A.id "editor-format", Events.on "change" (Decode.map config.editorFormatChanged (Decode.at [ "target", "value" ] Decode.string)) ]
                [ option [ A.value "markdown", A.selected (editor.format == "markdown") ] [ text (Translations.markdown active.texts) ]
                , option [ A.value "legacy", A.selected (editor.format == "legacy") ] [ text (Translations.originalFormat active.texts) ]
                ]
            ]
        , div []
            [ label [ A.for "editor-file" ] [ text (Translations.uploadFile active.texts) ]
            , input
                [ A.id "editor-file"
                , A.type_ "file"
                , Events.on "change" (Decode.maybe (Decode.at [ "target", "files", "0" ] File.decoder) |> Decode.map config.editorFileSelected)
                ]
                []
            , p [ A.class "muted" ] [ text (Translations.attachmentHelp active.texts) ]
            , p [ A.class "muted" ] [ text (Translations.imageDescriptionHelp active.texts) ]
            , if editor.uploading then
                p [ A.attribute "role" "status" ] [ text (Translations.loadingMessage active.texts) ]

              else
                text ""
            , ul [ A.class "attachment-list" ]
                (List.map
                    (\attachment ->
                        li []
                            [ text
                                (if String.isEmpty attachment.name then
                                    attachment.id

                                 else
                                    attachment.name
                                )
                            , button [ A.type_ "button", A.class "text-button", Events.onClick (config.editorRemoveAttachment attachment.id) ]
                                [ text (Translations.remove active.texts) ]
                            ]
                    )
                    editor.attachments
                )
            ]
        , case editor.problem of
            Just problem ->
                div [ A.class "field-error", A.attribute "role" "alert" ] [ text (problemText active.texts problem) ]

            Nothing ->
                text ""
        , case editor.conflict of
            Just source ->
                section [ A.class "conflict-panel" ]
                    [ h3 [] [ text (Translations.latestSource active.texts) ]
                    , pre [ A.dir "auto" ] [ text source.body ]
                    , div [ A.class "actions" ]
                        [ button [ A.type_ "button", A.class "outlined-button", Events.onClick config.editorKeepDraft ]
                            [ text (Translations.keepDraft active.texts) ]
                        , button [ A.type_ "button", A.class "filled-button", Events.onClick config.editorUseLatest ]
                            [ text (Translations.useLatest active.texts) ]
                        ]
                    ]

            Nothing ->
                text ""
        , button [ A.type_ "submit", A.class "filled-button", A.disabled editor.saving ]
            [ text
                (case editor.mode of
                    CreateTopic _ ->
                        Translations.publishTopic active.texts

                    CreateReply _ ->
                        Translations.publishReply active.texts

                    EditPost _ ->
                        Translations.saveChanges active.texts
                )
            ]
        ]


editorTitle : Config msg -> Active -> EditorState -> Html msg
editorTitle config active editor =
    div []
        [ label [ A.for "editor-title" ] [ text (Translations.topicTitle active.texts) ]
        , input [ A.id "editor-title", A.type_ "text", A.required True, A.value editor.title, Events.onInput config.editorTitleChanged ]
            []
        ]

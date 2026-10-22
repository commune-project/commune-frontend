module Feature.Editor.Update exposing (Msg(..), Outcome, load, update)

import Api
import App.Feedback exposing (Flash(..))
import Domain
import Feature.Editor.State exposing (..)
import File exposing (File)
import Html exposing (label)
import Json.Encode as Encode
import List
import Ports exposing (focus)
import Remote exposing (Remote(..))
import Route
import Url exposing (Url)


type Msg
    = StartReply String
    | EditorTitleChanged String
    | EditorBodyChanged String
    | EditorFormatChanged String
    | EditorRemoveAttachment String
    | EditorFileSelected (Maybe File)
    | EditorSubmit
    | EditorUseLatest
    | EditorKeepDraft
    | Saved EditorMode Api.Response
    | Reloaded Api.Response
    | Uploaded EditorMode Api.Response
    | SourceLoaded String Api.Response


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem, navigation : Maybe String }


type alias Working =
    { editor : Maybe EditorState
    , source : Remote Domain.Source
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    }


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message state =
    let
        ( next, command ) =
            updateWorking csrf
                message
                { editor = state.editor
                , source = state.source
                , flash = NoFlash
                , sessionProblem = Nothing
                , navigation = Nothing
                }
    in
    ( { editor = next.editor, source = next.source }
    , command
    , { flash = next.flash, sessionProblem = next.sessionProblem, navigation = next.navigation }
    )


authProblem : Working -> Api.Problem -> Working
authProblem model problem =
    if problem.status == 401 then
        { model | sessionProblem = Just problem }

    else
        model


urlEncode : String -> String
urlEncode =
    Url.percentEncode


updateWorking : String -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf message model =
    case message of
        StartReply postId ->
            ( { model | editor = Just (emptyEditor (CreateReply postId)) }, focus "editor-body" )

        EditorTitleChanged value ->
            setEditor model (\editor -> { editor | title = value, problem = Nothing }) Cmd.none

        EditorBodyChanged value ->
            setEditor model (\editor -> { editor | body = value, problem = Nothing }) Cmd.none

        EditorFormatChanged value ->
            setEditor model (\editor -> { editor | format = value, problem = Nothing }) Cmd.none

        EditorRemoveAttachment id ->
            setEditor model
                (\editor -> { editor | attachments = List.filter (\item -> item.id /= id) editor.attachments, problem = Nothing })
                Cmd.none

        EditorFileSelected maybeFile ->
            case ( maybeFile, model.editor ) of
                ( Just file, Just editor ) ->
                    ( { model | editor = Just { editor | uploading = True, problem = Nothing } }
                    , Api.upload csrf "post" file (Uploaded editor.mode)
                    )

                _ ->
                    ( model, Cmd.none )

        EditorSubmit ->
            case model.editor of
                Just editor ->
                    if editor.saving then
                        ( model, Cmd.none )

                    else
                        submitEditor csrf model editor

                Nothing ->
                    ( model, Cmd.none )

        EditorUseLatest ->
            case ( model.editor, model.editor |> Maybe.andThen .conflict ) of
                ( Just editor, Just source ) ->
                    ( { model
                        | editor =
                            Just
                                { editor
                                    | title = source.title
                                    , body = source.body
                                    , format = source.format
                                    , version = Just source.version
                                    , attachments = sourceAttachments source
                                    , conflict = Nothing
                                    , problem = Nothing
                                }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        EditorKeepDraft ->
            setEditor model (\editor -> { editor | conflict = Nothing }) Cmd.none

        Saved mode response ->
            case Api.decodeResponse Domain.post response of
                Ok post ->
                    ( { model
                        | editor = Nothing
                        , navigation =
                            Just
                                (Route.path
                                    (case mode of
                                        CreateReply parent ->
                                            Route.Post parent

                                        _ ->
                                            Route.Post post.id
                                    )
                                )
                      }
                    , Cmd.none
                    )

                Err problem ->
                    case model.editor of
                        Just editor ->
                            if problem.status == 409 && String.contains "edit_conflict" problem.detail then
                                ( { model | editor = Just { editor | saving = False, problem = Just problem }, source = Loading }
                                , case mode of
                                    EditPost postId ->
                                        Api.get ("/api/v1/posts/" ++ urlEncode postId ++ "/source") Reloaded

                                    _ ->
                                        Cmd.none
                                )

                            else
                                let
                                    base =
                                        authProblem model problem
                                in
                                ( { base | editor = Just { editor | saving = False, problem = Just problem } }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

        Reloaded response ->
            case Api.decodeResponse Domain.source response of
                Ok source ->
                    case model.editor of
                        Just editor ->
                            ( { model | editor = Just { editor | conflict = Just source }, source = Ready source }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                Err problem ->
                    ( { model | flash = FlashProblem problem }, Cmd.none )

        Uploaded mode response ->
            case Api.decodeResponse Domain.media response of
                Ok uploaded ->
                    case model.editor of
                        Just editor ->
                            if editor.mode /= mode then
                                ( model, Cmd.none )

                            else
                                let
                                    label =
                                        if String.isEmpty uploaded.name then
                                            uploaded.id

                                        else
                                            uploaded.name

                                    markdown =
                                        if String.startsWith "image/" uploaded.mediaType then
                                            "![" ++ label ++ "](" ++ uploaded.reference ++ ")"

                                        else
                                            "[" ++ label ++ "](" ++ uploaded.reference ++ ")"

                                    separator =
                                        if String.isEmpty (String.trim editor.body) then
                                            ""

                                        else
                                            "\n\n"
                                in
                                ( { model
                                    | editor =
                                        Just
                                            { editor
                                                | uploading = False
                                                , body = String.trimRight editor.body ++ separator ++ markdown ++ "\n"
                                                , attachments = editor.attachments ++ [ { id = uploaded.id, name = uploaded.name, reference = uploaded.reference } ]
                                            }
                                    , flash = FlashUploaded
                                  }
                                , focus "editor-body"
                                )

                        Nothing ->
                            ( model, Cmd.none )

                Err problem ->
                    ( { model
                        | flash = FlashUploadFailed
                        , editor = model.editor |> Maybe.map (\editor -> { editor | uploading = False, problem = Just problem })
                      }
                    , Cmd.none
                    )

        SourceLoaded id response ->
            case Api.decodeResponse Domain.source response of
                Ok source ->
                    ( { model
                        | source = Ready source
                        , editor =
                            Just
                                { mode = EditPost id
                                , title = source.title
                                , body = source.body
                                , format =
                                    if String.isEmpty source.format then
                                        "legacy"

                                    else
                                        source.format
                                , version = Just source.version
                                , attachments = sourceAttachments source
                                , uploading = False
                                , saving = False
                                , problem = Nothing
                                , conflict = Nothing
                                }
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( authProblem { model | source = Failed problem } problem, Cmd.none )


submitEditor : String -> Working -> EditorState -> ( Working, Cmd Msg )
submitEditor csrf model editor =
    let
        attachmentIds =
            Encode.list Encode.string (List.map .id editor.attachments)

        ( method, url, encodedBody ) =
            case editor.mode of
                CreateTopic targetCommunity ->
                    ( "POST"
                    , "/api/v1/communities/" ++ urlEncode targetCommunity ++ "/topics"
                    , Encode.encode 0
                        (Encode.object
                            [ ( "title", Encode.string editor.title )
                            , ( "body", Encode.string editor.body )
                            , ( "content_format", Encode.string editor.format )
                            , ( "attachment_ids", attachmentIds )
                            ]
                        )
                    )

                CreateReply postId ->
                    ( "POST"
                    , "/api/v1/posts/" ++ urlEncode postId ++ "/replies"
                    , Encode.encode 0
                        (Encode.object
                            [ ( "body", Encode.string editor.body )
                            , ( "content_format", Encode.string editor.format )
                            , ( "attachment_ids", attachmentIds )
                            ]
                        )
                    )

                EditPost postId ->
                    ( "PATCH"
                    , "/api/v1/posts/" ++ urlEncode postId
                    , "{\"expected_version\":"
                        ++ Maybe.withDefault "0" editor.version
                        ++ ",\"title\":"
                        ++ Encode.encode 0 (Encode.string editor.title)
                        ++ ",\"body\":"
                        ++ Encode.encode 0 (Encode.string editor.body)
                        ++ ",\"content_format\":"
                        ++ Encode.encode 0 (Encode.string editor.format)
                        ++ ",\"attachment_ids\":"
                        ++ Encode.encode 0 attachmentIds
                        ++ "}"
                    )
    in
    ( { model | editor = Just { editor | saving = True, problem = Nothing } }
    , Api.send csrf method url encodedBody (Saved editor.mode)
    )


setEditor : Working -> (EditorState -> EditorState) -> Cmd Msg -> ( Working, Cmd Msg )
setEditor model transform command =
    ( { model | editor = Maybe.map transform model.editor }, command )


load : String -> Model -> ( Model, Cmd Msg )
load id model =
    ( { model | source = Loading }
    , Api.get ("/api/v1/posts/" ++ urlEncode id ++ "/source") (SourceLoaded id)
    )

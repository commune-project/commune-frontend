module Feature.Report exposing (Action(..), Config, DialogAction(..), Model, Msg(..), Outcome, Target(..), close, initial, open, reportDialog, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import Generated.I18n as Translations
import Html exposing (Html, button, div, form, h2, label, p, text, textarea)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Remote exposing (Remote(..))
import Ui.Feedback exposing (problemText)
import Ui.Formatting exposing (boolText)


type Target
    = PostTarget String String
    | CommunityTarget String
    | PersonTarget String


type alias Model =
    { target : Maybe Target
    , reason : String
    , busy : Bool
    , problem : Maybe Api.Problem
    }


initial : Model
initial =
    { target = Nothing, reason = "", busy = False, problem = Nothing }


type Msg
    = Open Target
    | Close
    | ReasonChanged String
    | Submit
    | ActionDone Action Api.Response


type Action
    = SubmitAction


type DialogAction
    = OpenDialog
    | CloseDialog


type alias Outcome =
    { flash : Flash
    , sessionProblem : Maybe Api.Problem
    , dialog : Maybe DialogAction
    }


type alias Working =
    { target : Maybe Target
    , reason : String
    , busy : Bool
    , problem : Maybe Api.Problem
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    , dialog : Maybe DialogAction
    }


open : Target -> Model -> ( Model, Cmd Msg, Outcome )
open target _ =
    ( { initial | target = Just target }, Cmd.none, { flash = NoFlash, sessionProblem = Nothing, dialog = Just OpenDialog } )


close : Model -> ( Model, Cmd Msg, Outcome )
close _ =
    ( initial, Cmd.none, { flash = NoFlash, sessionProblem = Nothing, dialog = Just CloseDialog } )


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message state =
    let
        ( next, command ) =
            updateWorking csrf
                message
                { target = state.target
                , reason = state.reason
                , busy = state.busy
                , problem = state.problem
                , flash = NoFlash
                , sessionProblem = Nothing
                , dialog = Nothing
                }
    in
    ( { target = next.target, reason = next.reason, busy = next.busy, problem = next.problem }
    , command
    , { flash = next.flash, sessionProblem = next.sessionProblem, dialog = next.dialog }
    )


updateWorking : String -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf message model =
    case message of
        Open target ->
            ( { target = Just target
              , reason = ""
              , busy = False
              , problem = Nothing
              , flash = NoFlash
              , sessionProblem = Nothing
              , dialog = Just OpenDialog
              }
            , Cmd.none
            )

        Close ->
            ( { target = Nothing
              , reason = ""
              , busy = False
              , problem = Nothing
              , flash = NoFlash
              , sessionProblem = Nothing
              , dialog = Just CloseDialog
              }
            , Cmd.none
            )

        ReasonChanged value ->
            ( { model | reason = value, problem = Nothing }, Cmd.none )

        Submit ->
            case model.target of
                Just target ->
                    let
                        reason =
                            String.trim model.reason
                    in
                    if model.busy || String.isEmpty reason then
                        ( model, Cmd.none )

                    else
                        ( { model | busy = True, problem = Nothing }
                        , Api.send csrf
                            "POST"
                            "/api/v1/reports"
                            (Encode.encode 0 (reportPayload target reason))
                            (ActionDone SubmitAction)
                        )

                Nothing ->
                    ( model, Cmd.none )

        ActionDone SubmitAction response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { target = Nothing
                      , reason = ""
                      , busy = False
                      , problem = Nothing
                      , flash = FlashSaved
                      , sessionProblem = Nothing
                      , dialog = Just CloseDialog
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( { model
                        | busy = False
                        , problem = Just problem
                        , flash = FlashProblem problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )


reportPayload : Target -> String -> Encode.Value
reportPayload target reason =
    let
        ( kind, targetValue, communityId ) =
            case target of
                PostTarget id community ->
                    ( "post", id, community )

                CommunityTarget id ->
                    ( "community", id, id )

                PersonTarget actor ->
                    ( "person", actor, "" )
    in
    Encode.object
        ([ ( "target_kind", Encode.string kind )
         , ( "target_id", Encode.string targetValue )
         , ( "reason", Encode.string reason )
         ]
            ++ (if String.isEmpty communityId then
                    []

                else
                    [ ( "community_id", Encode.string communityId ) ]
               )
        )


type alias Config msg =
    { close : msg
    , reasonChanged : String -> msg
    , submit : msg
    }


reportDialog : Config msg -> Model -> Active -> Html msg
reportDialog config model active =
    case model.target of
        Nothing ->
            text ""

        Just target ->
            Html.node "dialog"
                [ A.id "report-dialog"
                , A.class "confirmation"
                , A.attribute "aria-labelledby" "report-title"
                , Events.on "close" (Decode.succeed config.close)
                , Events.on "cancel" (Decode.succeed config.close)
                ]
                [ form [ Events.onSubmit config.submit, A.class "form-stack" ]
                    [ h2 [ A.id "report-title" ] [ text (Translations.reportTitle active.texts) ]
                    , p [ A.class "metadata" ]
                        [ text (Translations.reportKind active.texts)
                        , text ": "
                        , text (targetKindLabel active.texts target)
                        , text " · "
                        , text (Translations.reportTarget active.texts)
                        , text ": "
                        , text (targetId target)
                        ]
                    , div []
                        [ label [ A.for "report-reason" ] [ text (Translations.reportReason active.texts) ]
                        , textarea
                            [ A.id "report-reason"
                            , A.value model.reason
                            , A.required True
                            , A.attribute "maxlength" "1000"
                            , A.attribute "aria-invalid" (boolText (model.problem /= Nothing))
                            , Events.onInput config.reasonChanged
                            ]
                            []
                        ]
                    , case model.problem of
                        Just problem ->
                            p [ A.class "field-error", A.attribute "role" "alert" ] [ text (problemText active.texts problem) ]

                        Nothing ->
                            text ""
                    , div [ A.class "dialog-actions" ]
                        [ button [ A.type_ "button", A.class "text-button", Events.onClick config.close ]
                            [ text (Translations.cancel active.texts) ]
                        , button [ A.type_ "submit", A.class "filled-button", A.disabled (model.busy || String.isEmpty (String.trim model.reason)) ]
                            [ text (Translations.reportSubmit active.texts) ]
                        ]
                    ]
                ]


targetKindLabel : Translations.I18n -> Target -> String
targetKindLabel texts target =
    case target of
        PostTarget _ _ ->
            Translations.reportPost texts

        CommunityTarget _ ->
            Translations.reportCommunity texts

        PersonTarget _ ->
            Translations.reportPerson texts


targetId : Target -> String
targetId target =
    case target of
        PostTarget id _ ->
            id

        CommunityTarget id ->
            id

        PersonTarget actor ->
            actor

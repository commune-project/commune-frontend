module Feature.AccountBlocks exposing (Action(..), Config, Model, Msg(..), Outcome, initial, load, pageAccountBlocks, reset, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Domain
import Generated.I18n as Translations
import Html exposing (Html, button, div, form, h2, input, label, li, option, p, section, select, span, text, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import List
import Remote exposing (Remote(..))
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Formatting exposing (formattedDate)
import Ui.Layout exposing (pageHeading)


type alias Model =
    { blocks : Remote (List Domain.AccountBlock)
    , kind : String
    , target : String
    , busy : Bool
    , problem : Maybe Api.Problem
    }


initial : Model
initial =
    { blocks = NotAsked
    , kind = "person"
    , target = ""
    , busy = False
    , problem = Nothing
    }


reset : Model -> Model
reset _ =
    initial


type Msg
    = KindChanged String
    | TargetChanged String
    | AddBlock
    | RemoveBlock String String
    | Loaded Api.Response
    | ActionDone Action Api.Response


type Action
    = AddAction
    | RemoveAction


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem }


type alias Working =
    { blocks : Remote (List Domain.AccountBlock)
    , kind : String
    , target : String
    , busy : Bool
    , problem : Maybe Api.Problem
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    }


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message state =
    let
        ( next, command ) =
            updateWorking csrf
                message
                { blocks = state.blocks
                , kind = state.kind
                , target = state.target
                , busy = state.busy
                , problem = state.problem
                , flash = NoFlash
                , sessionProblem = Nothing
                }
    in
    ( { blocks = next.blocks
      , kind = next.kind
      , target = next.target
      , busy = next.busy
      , problem = next.problem
      }
    , command
    , { flash = next.flash, sessionProblem = next.sessionProblem }
    )


updateWorking : String -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf message model =
    case message of
        KindChanged value ->
            ( { model | kind = value, problem = Nothing }, Cmd.none )

        TargetChanged value ->
            ( { model | target = value, problem = Nothing }, Cmd.none )

        AddBlock ->
            if model.busy || String.isEmpty (String.trim model.target) then
                ( model, Cmd.none )

            else
                ( { model | busy = True, problem = Nothing }
                , blockRequest csrf "POST" model.kind model.target AddAction
                )

        RemoveBlock kind target ->
            if model.busy then
                ( model, Cmd.none )

            else
                ( { model | busy = True, problem = Nothing }
                , blockRequest csrf "DELETE" kind target RemoveAction
                )

        Loaded response ->
            case Api.decodeResponse (Decode.field "items" (Decode.list Domain.accountBlock)) response of
                Ok blocks ->
                    ( { model | blocks = Ready blocks }, Cmd.none )

                Err problem ->
                    ( { model | blocks = Failed problem, problem = Just problem }
                    , Cmd.none
                    )

        ActionDone _ response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | busy = False, target = "", flash = FlashSaved }, loadCommand )

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


blockRequest : String -> String -> String -> String -> Action -> Cmd Msg
blockRequest csrf method kind target action =
    Api.send csrf
        method
        "/api/v1/account/blocks"
        (Encode.encode 0
            (Encode.object
                [ ( "kind", Encode.string kind )
                , ( "target", Encode.string target )
                ]
            )
        )
        (ActionDone action)


loadCommand : Cmd Msg
loadCommand =
    Api.get "/api/v1/account/blocks" Loaded


load : Model -> ( Model, Cmd Msg )
load model =
    ( { model | blocks = Loading, problem = Nothing }, loadCommand )


type alias Config msg =
    { retry : msg
    , kindChanged : String -> msg
    , targetChanged : String -> msg
    , addBlock : msg
    , confirmRemoveBlock : String -> String -> msg
    , formatted : Maybe Ui.Formatting.Formatting
    }


type alias ViewModel =
    { blocks : Remote (List Domain.AccountBlock)
    , kind : String
    , target : String
    , busy : Bool
    , problem : Maybe Api.Problem
    , auth : AuthState
    }


pageAccountBlocks : Config msg -> ViewModel -> Active -> Html msg
pageAccountBlocks config model active =
    pageHeading (Translations.blockTitle active.texts)
        (case model.auth of
            Authenticated _ ->
                section [ A.class "primary-column" ]
                    [ form [ Events.onSubmit config.addBlock, A.class "card form-stack" ]
                        [ p [ A.class "muted" ] [ text (Translations.blockHelp active.texts) ]
                        , div []
                            [ label [ A.for "block-kind" ] [ text (Translations.blockKind active.texts) ]
                            , select
                                [ A.id "block-kind"
                                , Events.on "change" (Decode.map config.kindChanged (Decode.at [ "target", "value" ] Decode.string))
                                ]
                                [ option [ A.value "person", A.selected (model.kind == "person") ] [ text (Translations.blockPerson active.texts) ]
                                , option [ A.value "community", A.selected (model.kind == "community") ] [ text (Translations.blockCommunity active.texts) ]
                                , option [ A.value "instance", A.selected (model.kind == "instance") ] [ text (Translations.blockInstance active.texts) ]
                                ]
                            ]
                        , div []
                            [ label [ A.for "block-target" ] [ text (Translations.blockTarget active.texts) ]
                            , input
                                [ A.id "block-target"
                                , A.type_ "text"
                                , A.value model.target
                                , Events.onInput config.targetChanged
                                ]
                                []
                            ]
                        , viewFormProblem active.texts model.problem
                        , button [ A.type_ "submit", A.class "filled-button", A.disabled (model.busy || String.isEmpty (String.trim model.target)) ]
                            [ text (Translations.addBlock active.texts) ]
                        ]
                    , viewRemote config.retry
                        active.texts
                        model.blocks
                        (\blocks ->
                            if List.isEmpty blocks then
                                p [ A.class "empty-state" ] [ text (Translations.noBlocks active.texts) ]

                            else
                                ul [ A.class "roster-list" ]
                                    (List.map
                                        (\block ->
                                            li []
                                                [ span [ A.class "chips" ]
                                                    [ span [ A.class "chip" ] [ text (blockKindLabel active.texts block.kind) ]
                                                    , span [ A.class "chip" ] [ text (formattedDate config.formatted block.createdAt) ]
                                                    ]
                                                , p [ A.dir "auto" ] [ text block.target ]
                                                , button
                                                    [ A.id ("block-remove-" ++ block.kind ++ "-" ++ block.target)
                                                    , A.type_ "button"
                                                    , A.class "text-button danger-text"
                                                    , A.disabled model.busy
                                                    , Events.onClick (config.confirmRemoveBlock block.kind block.target)
                                                    ]
                                                    [ text (Translations.removeBlock active.texts) ]
                                                ]
                                        )
                                        blocks
                                    )
                        )
                    ]

            _ ->
                loginRequired active.texts
        )


blockKindLabel : Translations.I18n -> String -> String
blockKindLabel texts kind =
    case kind of
        "person" ->
            Translations.blockPerson texts

        "community" ->
            Translations.blockCommunity texts

        _ ->
            Translations.blockInstance texts

module Feature.SiteAdmin.Update exposing (Action(..), LoadKind(..), Msg(..), Outcome, loadBans, loadModlog, loadReports, loadSettings, update)

import Api
import App.Feedback exposing (Flash(..))
import Dict
import Domain
import Feature.SiteAdmin.State exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import List
import Remote exposing (Remote(..))
import Route
import Set exposing (Set)
import Url exposing (Url)


type Msg
    = Loaded LoadKind Api.Response
    | SettingsLoaded Api.Response
    | UpvotesChanged Bool
    | DownvotesChanged Bool
    | SaveSettings
    | SettingsSaved Api.Response
    | ReportStateChanged String
    | ReportCommunityChanged String
    | ApplyReportFilter
    | ReportNoteChanged String String
    | ResolveReport String String
    | ReportResolved String String Api.Response
    | ModlogCommunityChanged String
    | ApplyModlogFilter
    | BanActorChanged String
    | BanReasonChanged String
    | BanExpiresChanged String
    | CreateBan
    | RemoveBan
    | BanDone Action Api.Response


type LoadKind
    = LoadReports
    | LoadModlog


type Action
    = BanAction


type alias Context =
    { csrf : String, url : Url }


type alias Outcome =
    { flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    , refreshModlog : Bool
    }


type alias Working =
    { model : Model
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    , refreshModlog : Bool
    }


update : Context -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update context message state =
    let
        ( next, command ) =
            updateWorking context
                message
                { model = state
                , flash = NoFlash
                , sessionProblem = Nothing
                , navigation = Nothing
                , refreshModlog = False
                }
    in
    ( next.model
    , command
    , { flash = next.flash
      , sessionProblem = next.sessionProblem
      , navigation = next.navigation
      , refreshModlog = next.refreshModlog
      }
    )


updateWorking : Context -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking context message state =
    let
        model =
            state.model
    in
    case message of
        Loaded kind response ->
            let
                updated =
                    case kind of
                        LoadReports ->
                            { model | reports = decodePage Domain.report response }

                        LoadModlog ->
                            { model | modlog = decodePage Domain.moderationLogEntry response }
            in
            ( { state
                | model = updated
                , sessionProblem = problemFor response
              }
            , Cmd.none
            )

        SettingsLoaded response ->
            case Api.decodeResponse Domain.voteSettings response of
                Ok settings ->
                    ( { state
                        | model =
                            { model
                                | voteSettings = Ready settings
                                , upvotesEnabled = settings.upvotesEnabled
                                , downvotesEnabled = settings.downvotesEnabled
                                , settingsProblem = Nothing
                            }
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( { state
                        | model =
                            { model
                                | voteSettings = Failed problem
                                , settingsProblem = Just problem
                            }
                        , sessionProblem = sessionProblem problem
                      }
                    , Cmd.none
                    )

        UpvotesChanged value ->
            ( { state | model = { model | upvotesEnabled = value, settingsProblem = Nothing } }, Cmd.none )

        DownvotesChanged value ->
            ( { state | model = { model | downvotesEnabled = value, settingsProblem = Nothing } }, Cmd.none )

        SaveSettings ->
            if model.settingsBusy then
                ( state, Cmd.none )

            else
                ( { state | model = { model | settingsBusy = True, settingsProblem = Nothing } }
                , Api.send context.csrf
                    "PUT"
                    "/api/v1/admin/vote-settings"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "upvotes_enabled", Encode.bool model.upvotesEnabled )
                            , ( "downvotes_enabled", Encode.bool model.downvotesEnabled )
                            ]
                        )
                    )
                    SettingsSaved
                )

        SettingsSaved response ->
            case Api.decodeResponse Domain.voteSettings response of
                Ok settings ->
                    ( { state
                        | model =
                            { model
                                | voteSettings = Ready settings
                                , upvotesEnabled = settings.upvotesEnabled
                                , downvotesEnabled = settings.downvotesEnabled
                                , settingsBusy = False
                                , settingsProblem = Nothing
                            }
                        , flash = FlashSaved
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( { state
                        | model = { model | settingsBusy = False, settingsProblem = Just problem }
                        , flash = FlashProblem problem
                        , sessionProblem = sessionProblem problem
                      }
                    , Cmd.none
                    )

        ReportStateChanged value ->
            ( { state | model = { model | reportState = value } }, Cmd.none )

        ReportCommunityChanged value ->
            ( { state | model = { model | reportCommunity = value } }, Cmd.none )

        ApplyReportFilter ->
            ( { state | navigation = Just (reportsPath model.reportState model.reportCommunity) }, Cmd.none )

        ReportNoteChanged id value ->
            ( { state | model = { model | reportNotes = Dict.insert id value model.reportNotes } }, Cmd.none )

        ResolveReport id resolution ->
            if Set.member id model.reportBusy then
                ( state, Cmd.none )

            else
                ( { state | model = { model | reportBusy = Set.insert id model.reportBusy } }
                , Api.send context.csrf
                    "POST"
                    ("/api/v1/reports/" ++ urlEncode id ++ "/resolve")
                    (Encode.encode 0
                        (Encode.object
                            [ ( "state", Encode.string resolution )
                            , ( "note", Encode.string (Dict.get id model.reportNotes |> Maybe.withDefault "") )
                            ]
                        )
                    )
                    (ReportResolved id resolution)
                )

        ReportResolved id _ response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { state
                        | model =
                            { model
                                | reportBusy = Set.remove id model.reportBusy
                                , reports = Loading
                            }
                        , flash = FlashSaved
                        , refreshModlog = True
                      }
                    , reportsCommand model
                    )

                Err problem ->
                    ( { state
                        | model =
                            { model
                                | reportBusy = Set.remove id model.reportBusy
                                , reports = Loading
                            }
                        , flash = FlashProblem problem
                        , sessionProblem = sessionProblem problem
                      }
                    , reportsCommand model
                    )

        ModlogCommunityChanged value ->
            ( { state | model = { model | modlogCommunity = value } }, Cmd.none )

        ApplyModlogFilter ->
            ( { state | navigation = Just (modlogPath model.modlogCommunity) }, Cmd.none )

        BanActorChanged value ->
            ( { state | model = { model | banActor = value, banProblem = Nothing } }, Cmd.none )

        BanReasonChanged value ->
            ( { state | model = { model | banReason = value, banProblem = Nothing } }, Cmd.none )

        BanExpiresChanged value ->
            ( { state | model = { model | banExpires = value, banProblem = Nothing } }, Cmd.none )

        CreateBan ->
            banRequest context state "POST"

        RemoveBan ->
            banRequest context state "DELETE"

        BanDone _ response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { state
                        | model =
                            { model
                                | banBusy = False
                                , banActor = ""
                                , banReason = ""
                                , banExpires = ""
                                , banProblem = Nothing
                            }
                        , flash = FlashSaved
                        , refreshModlog = True
                      }
                    , Cmd.none
                    )

                Err problem ->
                    ( { state
                        | model = { model | banBusy = False, banProblem = Just problem }
                        , flash = FlashProblem problem
                        , sessionProblem = sessionProblem problem
                      }
                    , Cmd.none
                    )


banRequest : Context -> Working -> String -> ( Working, Cmd Msg )
banRequest context state method =
    let
        model =
            state.model
    in
    if model.banBusy || String.isEmpty (String.trim model.banActor) || String.isEmpty (String.trim model.banReason) then
        ( state, Cmd.none )

    else
        ( { state | model = { model | banBusy = True, banProblem = Nothing } }
        , Api.send context.csrf
            method
            "/api/v1/admin/bans"
            (Encode.encode 0
                (Encode.object
                    ([ ( "actor", Encode.string (String.trim model.banActor) )
                     , ( "reason", Encode.string (String.trim model.banReason) )
                     ]
                        ++ (if String.isEmpty (String.trim model.banExpires) then
                                []

                            else
                                [ ( "expires_at", Encode.string (String.trim model.banExpires) ) ]
                           )
                    )
                )
            )
            (BanDone BanAction)
        )


decodePage : Decode.Decoder a -> Api.Response -> Remote (Domain.Page a)
decodePage decoder response =
    case Api.decodeResponse (Domain.page decoder) response of
        Ok page ->
            Ready page

        Err problem ->
            Failed problem


problemFor : Api.Response -> Maybe Api.Problem
problemFor response =
    if response.status >= 200 && response.status < 300 then
        Nothing

    else
        sessionProblem { status = response.status, detail = response.body }


sessionProblem : Api.Problem -> Maybe Api.Problem
sessionProblem problem =
    if problem.status == 401 then
        Just problem

    else
        Nothing


urlEncode : String -> String
urlEncode =
    Url.percentEncode


reportsPath : String -> String -> String
reportsPath state community =
    "/admin/reports"
        ++ query
            [ ( "state", state )
            , ( "community_id", community )
            ]


reportsApiPath : String -> String -> String
reportsApiPath state community =
    "/api/v1/reports"
        ++ query
            [ ( "state", state )
            , ( "community_id", community )
            ]


modlogPath : String -> String
modlogPath community =
    "/admin/modlog" ++ query [ ( "community_id", community ) ]


modlogApiPath : String -> String
modlogApiPath community =
    "/api/v1/modlog" ++ query [ ( "community_id", community ) ]


query : List ( String, String ) -> String
query values =
    values
        |> List.filter (\( _, value ) -> not (String.isEmpty (String.trim value)))
        |> List.map (\( key, value ) -> key ++ "=" ++ Url.percentEncode value)
        |> (\items ->
                if List.isEmpty items then
                    ""

                else
                    "?" ++ String.join "&" items
           )


loadSettings : Model -> ( Model, Cmd Msg )
loadSettings model =
    ( { model | voteSettings = Loading, settingsProblem = Nothing }
    , Api.get "/api/v1/site/vote-settings" SettingsLoaded
    )


loadReports : Url -> Model -> ( Model, Cmd Msg )
loadReports url model =
    let
        state =
            Route.query "state" url
                |> (\value ->
                        if String.isEmpty value then
                            model.reportState

                        else
                            value
                   )

        community =
            Route.query "community_id" url

        updated =
            { model | reports = Loading, reportState = state, reportCommunity = community }
    in
    ( updated, reportsCommand updated )


loadModlog : Url -> Model -> ( Model, Cmd Msg )
loadModlog url model =
    let
        community =
            Route.query "community_id" url

        updated =
            { model | modlog = Loading, modlogCommunity = community }
    in
    ( updated, modlogCommand updated )


loadBans : Model -> ( Model, Cmd Msg )
loadBans model =
    ( model, Cmd.none )


reportsCommand : Model -> Cmd Msg
reportsCommand model =
    Api.get (reportsApiPath model.reportState model.reportCommunity) (Loaded LoadReports)


modlogCommand : Model -> Cmd Msg
modlogCommand model =
    Api.get (modlogApiPath model.modlogCommunity) (Loaded LoadModlog)

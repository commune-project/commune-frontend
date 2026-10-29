module Feature.Notifications exposing (Action(..), Config, Model, Msg(..), Outcome, initial, load, notificationItem, notificationKind, pageNotifications, unread, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Domain
import Generated.I18n as Translations
import Html exposing (Html, a, bdi, button, div, li, p, section, span, strong, text, time, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import List
import Remote exposing (Remote(..))
import Route
import Ui.Feedback exposing (loginRequired, viewRemote)
import Ui.Formatting exposing (Formatting, formattedDate)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)


type alias Model =
    { notifications : Remote Domain.NotificationPage, unreadCount : Maybe String }


initial : Model
initial =
    { notifications = NotAsked, unreadCount = Nothing }


type Msg
    = MarkNoticeRead String
    | MarkAllNoticesRead
    | ActionDone Action Api.Response
    | Loaded Api.Response
    | UnreadLoaded Api.Response


type Action
    = ReadNoticeAction String
    | ReadAllAction


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem }


type alias Working =
    { notifications : Remote Domain.NotificationPage, unreadCount : Maybe String, flash : Flash, sessionProblem : Maybe Api.Problem }


update : String -> Url -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf url message state =
    let
        ( next, command ) =
            updateWorking csrf url message { notifications = state.notifications, unreadCount = state.unreadCount, flash = NoFlash, sessionProblem = Nothing }
    in
    ( { notifications = next.notifications, unreadCount = next.unreadCount }, command, { flash = next.flash, sessionProblem = next.sessionProblem } )


load : Url -> Cmd Msg
load url =
    Cmd.batch [ Api.get ("/api/v1/notifications?limit=20&offset=" ++ String.fromInt (Route.offset url)) Loaded, unread ]


unread : Cmd Msg
unread =
    Api.get "/api/v1/notifications/unread-count" UnreadLoaded


problemState : Working -> Api.Problem -> Working
problemState model problem =
    { model
        | flash = FlashProblem problem
        , sessionProblem =
            if problem.status == 401 then
                Just problem

            else
                Nothing
    }


urlEncode : String -> String
urlEncode =
    Url.percentEncode


updateWorking : String -> Url -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf url message model =
    case message of
        MarkNoticeRead id ->
            ( model, Api.send csrf "POST" ("/api/v1/notifications/" ++ urlEncode id ++ "/read") "" (ActionDone (ReadNoticeAction id)) )

        MarkAllNoticesRead ->
            case model.notifications of
                Ready page ->
                    ( model
                    , Api.send csrf
                        "POST"
                        "/api/v1/notifications/read-all"
                        (Encode.encode 0 (Encode.object [ ( "through_cursor", Encode.string page.cursor ) ]))
                        (ActionDone ReadAllAction)
                    )

                _ ->
                    ( model, Cmd.none )

        ActionDone action response ->
            case action of
                ReadNoticeAction id ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( model, load url )

                        Err problem ->
                            ( problemState model problem, Cmd.none )

                ReadAllAction ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( model, load url )

                        Err problem ->
                            ( problemState model problem, Cmd.none )

        Loaded response ->
            case Api.decodeResponse Domain.notificationPage response of
                Ok page ->
                    ( { model | notifications = Ready page }, Cmd.none )

                Err problem ->
                    ( { model
                        | notifications = Failed problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )

        UnreadLoaded response ->
            case Api.decodeResponse (Decode.field "count" Decode.int) response of
                Ok count ->
                    ( { model | unreadCount = Just (String.fromInt count) }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


type alias Config msg =
    { retry : msg
    , markNoticeRead : String -> msg
    , markAllNoticesRead : msg
    }


type alias ViewModel =
    { unreadCount : Maybe String
    , notifications : Remote Domain.NotificationPage
    , auth : AuthState
    , formatted : Maybe Formatting
    , url : Url
    }


pageNotifications : Config msg -> ViewModel -> Active -> Html msg
pageNotifications config model active =
    pageHeading (Translations.notificationsTitle active.texts)
        (section [ A.class "primary-column" ]
            [ case model.auth of
                Authenticated _ ->
                    div [ A.class "actions" ]
                        [ button [ A.class "outlined-button", Events.onClick config.markAllNoticesRead ]
                            [ text (Translations.markAllRead active.texts) ]
                        , case model.unreadCount of
                            Just count ->
                                span [ A.class "chip notification-unread-summary" ] [ text (Translations.unreadNotifications count active.texts) ]

                            Nothing ->
                                text ""
                        ]

                _ ->
                    loginRequired active.texts
            , viewRemote config.retry
                active.texts
                model.notifications
                (\page ->
                    if List.isEmpty page.items then
                        div [ A.class "stack" ]
                            [ p [ A.class "muted" ] [ text (Translations.noNotifications active.texts) ]
                            , viewPagination active.texts model.url page.offset page.limit 0
                            ]

                    else
                        div [ A.class "stack" ]
                            [ ul [ A.class "notification-list" ] (List.map (notificationItem config model active) page.items)
                            , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                            ]
                )
            ]
        )


notificationItem : Config msg -> ViewModel -> Active -> Domain.Notice -> Html msg
notificationItem config model active notice =
    li [ A.class "card" ]
        [ p [] [ strong [] [ bdi [] [ text notice.actor ] ], text " ", text (notificationKind active.texts notice.kind) ]
        , p [ A.class "metadata" ] [ time [ A.datetime notice.date, A.attribute "data-commune-time" "" ] [ text (formattedDate model.formatted notice.date) ] ]
        , div [ A.class "actions" ]
            [ a [ A.href (Route.path (Route.Post notice.post)) ] [ text (Translations.repliesTitle active.texts) ]
            , if notice.read then
                text ""

              else
                button [ A.class "text-button", Events.onClick (config.markNoticeRead notice.id) ]
                    [ text (Translations.markRead active.texts) ]
            ]
        ]


notificationKind : Translations.I18n -> String -> String
notificationKind texts kind =
    case kind of
        "reply" ->
            Translations.notificationReply texts

        "like" ->
            Translations.notificationLike texts

        "mention" ->
            Translations.notificationMention texts

        _ ->
            Translations.notificationOther texts

module Feature.Post exposing (Config, Model, Msg(..), Outcome, initial, likeKey, load, pagePost, reset, update, viewNested)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import Dict exposing (Dict)
import Domain
import Generated.I18n as Translations
import Html exposing (Html, button, div, h2, p, section, text)
import Html.Attributes as A
import Html.Events as Events
import List
import Remote exposing (Remote(..))
import Route
import Set exposing (Set)
import Ui.Feedback exposing (viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)


type alias Model =
    { post : Remote Domain.Post
    , replies : Remote (Domain.Page Domain.Post)
    , nestedReplies : Dict String (Remote (Domain.Page Domain.Post))
    , expandedReplies : Set String
    , busy : Set String
    }


initial : Model
initial =
    { post = NotAsked, replies = NotAsked, nestedReplies = Dict.empty, expandedReplies = Set.empty, busy = Set.empty }


likeKey : String -> String
likeKey id =
    "like-" ++ id


type Msg
    = ToggleReplies String
    | ToggleLike String Bool
    | ConfirmDelete String
    | Liked String Bool Api.Response
    | Deleted Api.Response
    | PostLoaded Api.Response
    | RepliesLoaded Api.Response
    | NestedLoaded String Api.Response


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem, navigation : Maybe String, like : Maybe ( String, Bool ) }


type alias Working =
    { post : Remote Domain.Post
    , replies : Remote (Domain.Page Domain.Post)
    , nestedReplies : Dict String (Remote (Domain.Page Domain.Post))
    , expandedReplies : Set String
    , busy : Set String
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    , like : Maybe ( String, Bool )
    }


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message state =
    let
        ( next, command ) =
            updateWorking csrf message { post = state.post, replies = state.replies, nestedReplies = state.nestedReplies, expandedReplies = state.expandedReplies, busy = state.busy, flash = NoFlash, sessionProblem = Nothing, navigation = Nothing, like = Nothing }
    in
    ( { post = next.post, replies = next.replies, nestedReplies = next.nestedReplies, expandedReplies = next.expandedReplies, busy = next.busy }, command, { flash = next.flash, sessionProblem = next.sessionProblem, navigation = next.navigation, like = next.like } )


urlEncode : String -> String
urlEncode =
    Url.percentEncode


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


updateWorking : String -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf message model =
    case message of
        ToggleReplies id ->
            if Set.member id model.expandedReplies then
                ( { model | expandedReplies = Set.remove id model.expandedReplies }, Cmd.none )

            else
                let
                    expanded =
                        { model | expandedReplies = Set.insert id model.expandedReplies }
                in
                if Dict.member id model.nestedReplies then
                    ( expanded, Cmd.none )

                else
                    ( { expanded | nestedReplies = Dict.insert id Loading expanded.nestedReplies }
                    , Api.get
                        ("/api/v1/posts/" ++ urlEncode id ++ "/replies?limit=20&offset=0")
                        (NestedLoaded id)
                    )

        ToggleLike id liked ->
            let
                key =
                    likeKey id
            in
            if Set.member key model.busy then
                ( model, Cmd.none )

            else
                ( { model | busy = Set.insert key model.busy }
                , Api.send csrf
                    (if liked then
                        "DELETE"

                     else
                        "POST"
                    )
                    ("/api/v1/posts/" ++ urlEncode id ++ "/likes")
                    ""
                    (Liked id liked)
                )

        ConfirmDelete id ->
            ( model, Api.send csrf "DELETE" ("/api/v1/posts/" ++ urlEncode id) "" Deleted )

        Liked id liked response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | busy = Set.remove (likeKey id) model.busy, like = Just ( id, liked ) }, Cmd.none )

                Err problem ->
                    ( problemState { model | busy = Set.remove (likeKey id) model.busy } problem, Cmd.none )

        Deleted response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | flash = FlashDeleted, navigation = Just "/" }, Cmd.none )

                Err problem ->
                    ( problemState model problem, Cmd.none )

        PostLoaded response ->
            case Api.decodeResponse Domain.post response of
                Ok post ->
                    ( { model | post = Ready post }, Cmd.none )

                Err problem ->
                    ( { model
                        | post = Failed problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )

        RepliesLoaded response ->
            case Api.decodeResponse (Domain.page Domain.post) response of
                Ok page ->
                    ( { model | replies = Ready page }, Cmd.none )

                Err problem ->
                    ( { model
                        | replies = Failed problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )

        NestedLoaded parent response ->
            case Api.decodeResponse (Domain.page Domain.post) response of
                Ok page ->
                    ( { model | nestedReplies = Dict.insert parent (Ready page) model.nestedReplies }, Cmd.none )

                Err problem ->
                    ( { model
                        | sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                        , nestedReplies =
                            if response.status >= 200 && response.status < 300 then
                                model.nestedReplies

                            else
                                Dict.insert parent (Failed problem) model.nestedReplies
                      }
                    , Cmd.none
                    )


type alias Config msg =
    { retry : msg
    , postCard : Domain.Post -> Html msg
    , startReply : String -> msg
    , editor : Html msg
    }


type alias ViewModel =
    { post : Remote Domain.Post
    , replies : Remote (Domain.Page Domain.Post)
    , nestedReplies : Dict String (Remote (Domain.Page Domain.Post))
    , url : Url
    }


pagePost : Config msg -> ViewModel -> Active -> String -> Html msg
pagePost config model active postId =
    pageHeading
        (case model.post of
            Ready post ->
                if String.isEmpty post.title then
                    Translations.repliesTitle active.texts

                else
                    post.title

            _ ->
                Translations.repliesTitle active.texts
        )
        (section [ A.class "primary-column" ]
            [ viewRemote config.retry
                active.texts
                model.post
                (\post ->
                    div [ A.class "stack" ]
                        [ config.postCard post
                        , if post.canReply && post.deleted == False then
                            button [ A.class "filled-button", Events.onClick (config.startReply post.id) ]
                                [ text (Translations.reply active.texts) ]

                          else
                            text ""
                        , config.editor
                        ]
                )
            , h2 [] [ text (Translations.repliesTitle active.texts) ]
            , viewRemote config.retry
                active.texts
                model.replies
                (\page ->
                    if List.isEmpty page.items then
                        emptyWithPagination active.texts model.url page

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map config.postCard page.items)
                            , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                            ]
                )
            ]
        )


viewNested : Config msg -> Active -> String -> ViewModel -> Html msg
viewNested config active parent model =
    case Dict.get parent model.nestedReplies of
        Just nested ->
            viewRemote config.retry
                active.texts
                nested
                (\page ->
                    div [ A.class "nested" ]
                        (if List.isEmpty page.items then
                            [ p [ A.class "muted" ] [ text (Translations.noReplies active.texts) ] ]

                         else
                            List.map config.postCard page.items
                        )
                )

        Nothing ->
            text ""


reset : Model -> Model
reset model =
    { model | post = NotAsked, replies = NotAsked, nestedReplies = Dict.empty, expandedReplies = Set.empty }


load : String -> Url -> Model -> ( Model, Cmd Msg )
load id url model =
    ( { model | post = Loading, replies = Loading }
    , Cmd.batch
        [ Api.get ("/api/v1/posts/" ++ urlEncode id) PostLoaded
        , Api.get ("/api/v1/posts/" ++ urlEncode id ++ "/replies?limit=20&offset=" ++ String.fromInt (Route.offset url)) RepliesLoaded
        ]
    )

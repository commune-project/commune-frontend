module Feature.Community exposing (Config, Model, Msg(..), initial, load, pageCommunities, pageCommunity, update)

import Api
import App.Context exposing (Active)
import Domain
import Generated.I18n as Translations
import Html exposing (Html, a, div, h2, p, section, text)
import Html.Attributes as A
import List
import Remote exposing (Remote(..))
import Route
import Ui.CommunityCard exposing (communityCard)
import Ui.Feedback exposing (viewRemote)
import Ui.Formatting exposing (policyLabel)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)


type alias Model =
    { communities : Remote (Domain.Page Domain.Community)
    , community : Remote Domain.Community
    , communityTopics : Remote (Domain.Page Domain.Post)
    }


initial : Model
initial =
    { communities = NotAsked, community = NotAsked, communityTopics = NotAsked }


type Msg
    = CommunitiesLoaded Api.Response
    | CommunityLoaded Api.Response
    | TopicsLoaded Api.Response


sessionProblem : Api.Problem -> Maybe Api.Problem
sessionProblem problem =
    if problem.status == 401 then
        Just problem

    else
        Nothing


update : Msg -> Model -> ( Model, Maybe Api.Problem )
update message model =
    case message of
        CommunitiesLoaded response ->
            case Api.decodeResponse (Domain.page Domain.community) response of
                Ok page ->
                    ( { model | communities = Ready page }, Nothing )

                Err problem ->
                    ( { model | communities = Failed problem }, sessionProblem problem )

        CommunityLoaded response ->
            case Api.decodeResponse Domain.community response of
                Ok community ->
                    ( { model | community = Ready community }, Nothing )

                Err problem ->
                    ( { model | community = Failed problem }, sessionProblem problem )

        TopicsLoaded response ->
            case Api.decodeResponse (Domain.page Domain.post) response of
                Ok page ->
                    ( { model | communityTopics = Ready page }, Nothing )

                Err problem ->
                    ( { model | communityTopics = Failed problem }, sessionProblem problem )


load : Route.Route -> Url -> Model -> ( Model, Cmd Msg )
load route url model =
    case route of
        Route.Communities ->
            ( { model | communities = Loading }, Api.get ("/api/v1/communities?limit=20&offset=" ++ String.fromInt (Route.offset url)) CommunitiesLoaded )

        Route.Community id ->
            ( { model | community = Loading, communityTopics = Loading }, Cmd.batch [ Api.get ("/api/v1/communities/" ++ Url.percentEncode id) CommunityLoaded, Api.get ("/api/v1/communities/" ++ Url.percentEncode id ++ "/topics?limit=20&offset=" ++ String.fromInt (Route.offset url)) TopicsLoaded ] )

        Route.NewTopic id ->
            ( { model | community = Loading }, Api.get ("/api/v1/communities/" ++ Url.percentEncode id) CommunityLoaded )

        _ ->
            ( model, Cmd.none )


type alias Config msg =
    { retry : msg
    , postCard : Domain.Post -> Html msg
    }


type alias ViewModel =
    { communities : Remote (Domain.Page Domain.Community)
    , community : Remote Domain.Community
    , communityTopics : Remote (Domain.Page Domain.Post)
    , url : Url
    }


pageCommunities : Config msg -> ViewModel -> Active -> Html msg
pageCommunities config model active =
    pageHeading (Translations.communitiesTitle active.texts)
        (section [ A.class "stack" ]
            [ p [ A.class "muted" ] [ text (Translations.communitiesIntro active.texts) ]
            , viewRemote config.retry
                active.texts
                model.communities
                (\page ->
                    if List.isEmpty page.items then
                        emptyWithPagination active.texts model.url page

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map (communityCard active.texts) page.items)
                            , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                            ]
                )
            ]
        )


pageCommunity : Config msg -> ViewModel -> Active -> String -> Html msg
pageCommunity config model active id =
    pageHeading
        (case model.community of
            Ready community ->
                community.title

            _ ->
                Translations.communitiesTitle active.texts
        )
        (section [ A.class "primary-column" ]
            [ viewRemote config.retry
                active.texts
                model.community
                (\community ->
                    div [ A.class "stack" ]
                        [ p [ A.class "metadata" ]
                            [ text
                                (Translations.policySummary
                                    { read = policyLabel active.texts community.readPolicy
                                    , post = policyLabel active.texts community.postPolicy
                                    }
                                    active.texts
                                )
                            ]
                        , if String.isEmpty community.description then
                            text ""

                          else
                            p [ A.dir "auto" ] [ text community.description ]
                        , div [ A.class "actions" ]
                            [ if community.canPost then
                                a [ A.class "filled-button", A.href (Route.path (Route.NewTopic community.id)) ]
                                    [ text (Translations.publishTopic active.texts) ]

                              else
                                text ""
                            , if community.canManage then
                                a [ A.class "outlined-button", A.href (Route.path (Route.Manage community.id)) ]
                                    [ text (Translations.manageTitle active.texts) ]

                              else
                                text ""
                            ]
                        ]
                )
            , h2 [] [ text (Translations.latestTitle active.texts) ]
            , viewRemote config.retry
                active.texts
                model.communityTopics
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

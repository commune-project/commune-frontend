module Feature.Community exposing (Config, Model, Msg(..), Outcome, ViewModel, initial, load, pageCommunities, pageCommunity, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Domain
import Generated.I18n as Translations
import Html exposing (Html, a, button, div, h2, p, section, span, text)
import Html.Attributes as A
import Html.Events as Events
import List
import Remote exposing (Remote(..))
import Route
import Set exposing (Set)
import Ui.CommunityCard exposing (communityCard)
import Ui.Feedback exposing (problemText, viewRemote)
import Ui.Formatting exposing (policyLabel)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)


type alias Model =
    { communities : Remote (Domain.Page Domain.Community)
    , community : Remote Domain.Community
    , communityTopics : Remote (Domain.Page Domain.Post)
    , busy : Set String
    , problem : Maybe Api.Problem
    }


initial : Model
initial =
    { communities = NotAsked, community = NotAsked, communityTopics = NotAsked, busy = Set.empty, problem = Nothing }


type Msg
    = CommunitiesLoaded Api.Response
    | CommunityLoaded Api.Response
    | TopicsLoaded Api.Response
    | ToggleFollow Bool
    | FollowDone Bool Api.Response


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem }


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message model =
    case message of
        ToggleFollow following ->
            if Set.member "follow" model.busy then
                ( model, Cmd.none, { flash = NoFlash, sessionProblem = Nothing } )

            else
                case model.community of
                    Ready community ->
                        ( { model | busy = Set.insert "follow" model.busy, problem = Nothing }
                        , Api.send csrf
                            (if following then
                                "DELETE"

                             else
                                "POST"
                            )
                            ("/api/v1/communities/" ++ Url.percentEncode community.id ++ "/follow")
                            ""
                            (FollowDone following)
                        , { flash = NoFlash, sessionProblem = Nothing }
                        )

                    _ ->
                        ( model, Cmd.none, { flash = NoFlash, sessionProblem = Nothing } )

        FollowDone _ response ->
            case Api.decodeUnit response of
                Ok () ->
                    case model.community of
                        Ready community ->
                            ( { model | busy = Set.remove "follow" model.busy, community = Loading }
                            , Api.get ("/api/v1/communities/" ++ Url.percentEncode community.id) CommunityLoaded
                            , { flash = FlashSaved, sessionProblem = Nothing }
                            )

                        _ ->
                            ( { model | busy = Set.remove "follow" model.busy }
                            , Cmd.none
                            , { flash = FlashSaved, sessionProblem = Nothing }
                            )

                Err problem ->
                    ( { model | busy = Set.remove "follow" model.busy, problem = Just problem }
                    , Cmd.none
                    , { flash = FlashProblem problem
                      , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    )

        CommunitiesLoaded response ->
            case Api.decodeResponse (Domain.page Domain.community) response of
                Ok page ->
                    ( { model | communities = Ready page }, Cmd.none, { flash = NoFlash, sessionProblem = Nothing } )

                Err problem ->
                    ( { model | communities = Failed problem }
                    , Cmd.none
                    , { flash = NoFlash
                      , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    )

        CommunityLoaded response ->
            case Api.decodeResponse Domain.community response of
                Ok community ->
                    ( { model | community = Ready community }, Cmd.none, { flash = NoFlash, sessionProblem = Nothing } )

                Err problem ->
                    ( { model | community = Failed problem }
                    , Cmd.none
                    , { flash = NoFlash
                      , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    )

        TopicsLoaded response ->
            case Api.decodeResponse (Domain.page Domain.post) response of
                Ok page ->
                    ( { model | communityTopics = Ready page }, Cmd.none, { flash = NoFlash, sessionProblem = Nothing } )

                Err problem ->
                    ( { model | communityTopics = Failed problem }
                    , Cmd.none
                    , { flash = NoFlash
                      , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    )


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
    , toggleFollow : Bool -> msg
    , reportCommunity : String -> msg
    }


type alias ViewModel =
    { communities : Remote (Domain.Page Domain.Community)
    , community : Remote Domain.Community
    , communityTopics : Remote (Domain.Page Domain.Post)
    , busy : Set String
    , problem : Maybe Api.Problem
    , auth : AuthState
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
                            , followControl config model active community
                            , if canReport model.auth then
                                button
                                    [ A.type_ "button"
                                    , A.class "outlined-button"
                                    , Events.onClick (config.reportCommunity community.id)
                                    ]
                                    [ text (Translations.reportCommunity active.texts) ]

                              else
                                text ""
                            ]
                        , p [ A.class "metadata" ]
                            [ text (Translations.followPolicy active.texts ++ ": ")
                            , text (followPolicyLabel active.texts community.followPolicy)
                            , text " · "
                            , text (Translations.followers active.texts ++ ": ")
                            , text (String.fromInt community.followerCount)
                            ]
                        , case model.problem of
                            Just problem ->
                                p [ A.class "field-error", A.attribute "role" "alert" ] [ text (problemText active.texts problem) ]

                            Nothing ->
                                text ""
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


canReport : AuthState -> Bool
canReport auth =
    case auth of
        Authenticated _ ->
            True

        _ ->
            False


followControl : Config msg -> ViewModel -> Active -> Domain.Community -> Html msg
followControl config model active community =
    if community.followState == "pending" then
        span [ A.class "chip" ] [ text (Translations.followPending active.texts) ]

    else if community.following then
        button
            [ A.type_ "button"
            , A.class "outlined-button"
            , A.disabled (Set.member "follow" model.busy)
            , Events.onClick (config.toggleFollow True)
            ]
            [ text (Translations.unfollow active.texts) ]

    else if community.canFollow then
        button
            [ A.type_ "button"
            , A.class "filled-button"
            , A.disabled (Set.member "follow" model.busy)
            , Events.onClick (config.toggleFollow False)
            ]
            [ text (Translations.follow active.texts) ]

    else
        span [ A.class "chip" ] [ text (followPolicyLabel active.texts community.followPolicy) ]


followPolicyLabel : Translations.I18n -> String -> String
followPolicyLabel texts policy =
    case policy of
        "members" ->
            Translations.followPolicyMembers texts

        "approval" ->
            Translations.followPolicyApproval texts

        "disabled" ->
            Translations.followPolicyDisabled texts

        _ ->
            Translations.followPolicyOpen texts

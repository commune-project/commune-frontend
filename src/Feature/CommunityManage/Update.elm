module Feature.CommunityManage.Update exposing (Action(..), LoadKind(..), Msg(..), Outcome, load, update)

import Api
import App.Feedback exposing (Flash(..))
import Domain
import Feature.CommunityManage.State exposing (..)
import Json.Encode as Encode
import Remote exposing (Remote(..))
import Route
import Set exposing (Set)
import Url


type Msg
    = Loaded LoadKind Api.Response
    | ActionDone Action Api.Response
    | ManageActorChanged String
    | ManagePostChanged String
    | ManageContextChanged String
    | ManageReadChanged String
    | ManagePostPolicyChanged String
    | ManageApplyPolicy
    | ManageAddMember
    | ManageRemoveMember String
    | ManageAddManager
    | ManageRemoveManager String
    | ManagePreviousMembers
    | ManageNextMembers
    | ManagePreviousManagers
    | ManageNextManagers
    | ManagePostAction String ManagePostAction


type LoadKind
    = LoadManageCommunity String
    | LoadMembers String Int
    | LoadManagers String Int


type Action
    = ManageAction String
    | ManagePostActionDone String ManagePostAction


type alias Context =
    { csrf : String, route : Route.Route }


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem }


type alias Working =
    { manage : Maybe ManageState, busy : Set String, flash : Flash, sessionProblem : Maybe Api.Problem }


update : Context -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update context message state =
    let
        ( next, command ) =
            updateWorking context message { manage = state.manage, busy = state.busy, flash = NoFlash, sessionProblem = Nothing }
    in
    ( { manage = next.manage, busy = next.busy }, command, { flash = next.flash, sessionProblem = next.sessionProblem } )


load : String -> ManageState -> Model -> ( Model, Cmd Msg )
load id manage state =
    ( { state | manage = Just manage }
    , Cmd.batch
        [ Api.get ("/api/v1/communities/" ++ urlEncode id) (Loaded (LoadManageCommunity id))
        , Api.get ("/api/v1/communities/" ++ urlEncode id ++ "/members?limit=20&offset=" ++ String.fromInt manage.memberOffset) (Loaded (LoadMembers id manage.memberOffset))
        , Api.get ("/api/v1/communities/" ++ urlEncode id ++ "/managers?limit=20&offset=" ++ String.fromInt manage.managerOffset) (Loaded (LoadManagers id manage.managerOffset))
        ]
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


updateWorking : Context -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking context message model =
    case message of
        ManageActorChanged value ->
            setManage model (\manage -> { manage | actor = value, problem = Nothing }) Cmd.none

        ManagePostChanged value ->
            setManage model (\manage -> { manage | postId = value, problem = Nothing }) Cmd.none

        ManageContextChanged value ->
            setManage model (\manage -> { manage | contextId = value, problem = Nothing }) Cmd.none

        ManageReadChanged value ->
            setManage model
                (\manage ->
                    { manage
                        | readPolicy = value
                        , postPolicy =
                            if value == "members" && manage.postPolicy == "eligible_users" then
                                "members"

                            else
                                manage.postPolicy
                    }
                )
                Cmd.none

        ManagePostPolicyChanged value ->
            setManage model
                (\manage ->
                    { manage
                        | postPolicy = value
                        , readPolicy =
                            if value == "eligible_users" && manage.readPolicy == "members" then
                                "eligible_users"

                            else
                                manage.readPolicy
                    }
                )
                Cmd.none

        ManageApplyPolicy ->
            case model.manage of
                Just manage ->
                    manageRequest context
                        model
                        "policy"
                        "PUT"
                        ("/api/v1/communities/" ++ urlEncode (communityId context.route) ++ "/policy")
                        (Encode.encode 0
                            (Encode.object
                                [ ( "read_policy", Encode.string manage.readPolicy )
                                , ( "post_policy", Encode.string manage.postPolicy )
                                ]
                            )
                        )

                Nothing ->
                    ( model, Cmd.none )

        ManageAddMember ->
            manageActorRequest context model "add-member" "POST" "members"

        ManageRemoveMember actor ->
            manageActorRequestFor context model "remove-member" "DELETE" "members" actor

        ManageAddManager ->
            manageActorRequest context model "add-manager" "POST" "managers"

        ManageRemoveManager actor ->
            manageActorRequestFor context model "remove-manager" "DELETE" "managers" actor

        ManagePreviousMembers ->
            managePage context model True -20

        ManageNextMembers ->
            managePage context model True 20

        ManagePreviousManagers ->
            managePage context model False -20

        ManageNextManagers ->
            managePage context model False 20

        ManagePostAction id action ->
            managePostRequest context model id action

        ActionDone (ManageAction key) response ->
            case Api.decodeUnit response of
                Ok () ->
                    let
                        changed =
                            { model | flash = FlashSaved }
                    in
                    case context.route of
                        Route.Manage id ->
                            loadManageState 0
                                id
                                (Maybe.withDefault emptyManage (model.manage |> Maybe.map (\manage -> { manage | problem = Nothing })))
                                changed

                        _ ->
                            ( changed, Cmd.none )

                Err problem ->
                    let
                        base =
                            authProblem model problem
                    in
                    ( { base
                        | flash = FlashProblem problem
                        , manage = model.manage |> Maybe.map (\manage -> { manage | problem = Just problem })
                      }
                    , Cmd.none
                    )

        ActionDone (ManagePostActionDone key managedAction) response ->
            case Api.decodeUnit response of
                Ok () ->
                    let
                        changed =
                            { model | flash = FlashSaved }
                    in
                    case context.route of
                        Route.Manage id ->
                            loadManageState 0
                                id
                                (Maybe.withDefault emptyManage (model.manage |> Maybe.map (\manage -> { manage | problem = Nothing })))
                                changed

                        _ ->
                            ( changed, Cmd.none )

                Err problem ->
                    let
                        base =
                            authProblem model problem
                    in
                    ( { base
                        | flash = FlashProblem problem
                        , manage = model.manage |> Maybe.map (\manage -> { manage | problem = Just problem })
                      }
                    , Cmd.none
                    )

        Loaded kind response ->
            let
                setCommunity result =
                    case result of
                        Ok community ->
                            updateManageRecord model (\manage -> { manage | community = Ready community, readPolicy = community.readPolicy, postPolicy = community.postPolicy })

                        Err problem ->
                            updateManageRecord model (\manage -> { manage | community = Failed problem, problem = Just problem })

                setRoster members result =
                    case result of
                        Ok page ->
                            updateManageRecord model
                                (\manage ->
                                    if members then
                                        { manage | members = Ready page }

                                    else
                                        { manage | managers = Ready page }
                                )

                        Err problem ->
                            updateManageRecord model
                                (\manage ->
                                    if members then
                                        { manage | members = Failed problem, problem = Just problem }

                                    else
                                        { manage | managers = Failed problem, problem = Just problem }
                                )
            in
            ( case kind of
                LoadManageCommunity _ ->
                    setCommunity (Api.decodeResponse Domain.community response)

                LoadMembers _ _ ->
                    setRoster True (Api.decodeResponse (Domain.page Domain.roster) response)

                LoadManagers _ _ ->
                    setRoster False (Api.decodeResponse (Domain.page Domain.roster) response)
            , Cmd.none
            )


manageRequest : Context -> Working -> String -> String -> String -> String -> ( Working, Cmd Msg )
manageRequest context model key method url body =
    if Set.member key model.busy then
        ( model, Cmd.none )

    else
        ( { model | busy = Set.insert key model.busy }
        , Api.send context.csrf method url body (ActionDone (ManageAction key))
        )


manageActorRequest : Context -> Working -> String -> String -> String -> ( Working, Cmd Msg )
manageActorRequest context model key method section =
    case model.manage of
        Just manage ->
            manageActorRequestWith context model key method section manage.actor

        Nothing ->
            ( model, Cmd.none )


manageActorRequestFor : Context -> Working -> String -> String -> String -> String -> ( Working, Cmd Msg )
manageActorRequestFor context model key method section actor =
    manageActorRequestWith context model key method section actor


manageActorRequestWith : Context -> Working -> String -> String -> String -> String -> ( Working, Cmd Msg )
manageActorRequestWith context model key method section actor =
    manageRequest context
        model
        key
        method
        ("/api/v1/communities/" ++ urlEncode (communityId context.route) ++ "/" ++ section)
        (Encode.encode 0 (Encode.object [ ( "actor", Encode.string actor ) ]))


managePage : Context -> Working -> Bool -> Int -> ( Working, Cmd Msg )
managePage context model members delta =
    case model.manage of
        Just manage ->
            let
                updated =
                    if members then
                        { manage | memberOffset = max 0 (manage.memberOffset + delta) }

                    else
                        { manage | managerOffset = max 0 (manage.managerOffset + delta) }
            in
            case context.route of
                Route.Manage id ->
                    loadManageState 0 id updated model

                _ ->
                    ( model, Cmd.none )

        Nothing ->
            ( model, Cmd.none )


managePostRequest : Context -> Working -> String -> ManagePostAction -> ( Working, Cmd Msg )
managePostRequest context model postId action =
    let
        id =
            communityId context.route

        key =
            "manage-post-" ++ postId ++ "-" ++ manageActionKey action

        ( method, url, body ) =
            case action of
                RemoveCommunityPost ->
                    ( "POST", "/api/v1/communities/" ++ urlEncode id ++ "/removals", Encode.object [ ( "post_id", Encode.string postId ) ] )

                RestoreCommunityPost ->
                    ( "DELETE", "/api/v1/communities/" ++ urlEncode id ++ "/removals", Encode.object [ ( "post_id", Encode.string postId ) ] )

                HideSitePost ->
                    ( "POST", "/api/v1/posts/" ++ urlEncode postId ++ "/hide", Encode.object [] )

                UnhideSitePost ->
                    ( "DELETE", "/api/v1/posts/" ++ urlEncode postId ++ "/hide", Encode.object [] )

                ImportSitePost ->
                    ( "POST", "/api/v1/posts/" ++ urlEncode postId ++ "/import", Encode.object [] )

                AcceptSubmission ->
                    ( "POST", "/api/v1/communities/" ++ urlEncode id ++ "/submissions", Encode.object [ ( "post_id", Encode.string postId ), ( "state", Encode.string "accepted" ) ] )

                RejectSubmission ->
                    ( "POST", "/api/v1/communities/" ++ urlEncode id ++ "/submissions", Encode.object [ ( "post_id", Encode.string postId ), ( "state", Encode.string "rejected" ) ] )

                BackfillDiscussion ->
                    let
                        contextId =
                            model.manage |> Maybe.map .contextId |> Maybe.withDefault ""
                    in
                    ( "POST", "/api/v1/contexts/" ++ urlEncode contextId ++ "/backfill", Encode.object [] )
    in
    manageRequest context model key method url (Encode.encode 0 body)


setManage : Working -> (ManageState -> ManageState) -> Cmd Msg -> ( Working, Cmd Msg )
setManage model transform command =
    ( { model | manage = Maybe.map transform model.manage }, command )


updateManageRecord : Working -> (ManageState -> ManageState) -> Working
updateManageRecord model transform =
    { model | manage = Maybe.map transform model.manage }


loadManageState : Int -> String -> ManageState -> Working -> ( Working, Cmd Msg )
loadManageState epoch id manage model =
    ( { model | manage = Just manage }
    , Cmd.batch
        [ Api.get ("/api/v1/communities/" ++ urlEncode id) (Loaded (LoadManageCommunity id))
        , Api.get ("/api/v1/communities/" ++ urlEncode id ++ "/members?limit=20&offset=" ++ String.fromInt manage.memberOffset) (Loaded (LoadMembers id manage.memberOffset))
        , Api.get ("/api/v1/communities/" ++ urlEncode id ++ "/managers?limit=20&offset=" ++ String.fromInt manage.managerOffset) (Loaded (LoadManagers id manage.managerOffset))
        ]
    )

module Feature.CommunityManage.State exposing (..)

import Api
import Domain
import Remote exposing (Remote(..))
import Route
import Set exposing (Set)


type alias ManageState =
    { community : Remote Domain.Community
    , members : Remote (Domain.Page Domain.Roster)
    , managers : Remote (Domain.Page Domain.Roster)
    , memberOffset : Int
    , managerOffset : Int
    , actor : String
    , postId : String
    , contextId : String
    , readPolicy : String
    , postPolicy : String
    , problem : Maybe Api.Problem
    }


type ManagePostAction
    = RemoveCommunityPost
    | RestoreCommunityPost
    | HideSitePost
    | UnhideSitePost
    | ImportSitePost
    | AcceptSubmission
    | RejectSubmission
    | BackfillDiscussion


emptyManage : ManageState
emptyManage =
    { community = NotAsked
    , members = NotAsked
    , managers = NotAsked
    , memberOffset = 0
    , managerOffset = 0
    , actor = ""
    , postId = ""
    , contextId = ""
    , readPolicy = "eligible_users"
    , postPolicy = "eligible_users"
    , problem = Nothing
    }


normalizeManagePolicies : ManageState -> ManageState
normalizeManagePolicies manage =
    if manage.postPolicy == "eligible_users" && manage.readPolicy == "members" then
        { manage | readPolicy = "eligible_users" }

    else
        manage


manageActionKey : ManagePostAction -> String
manageActionKey action =
    case action of
        RemoveCommunityPost ->
            "remove"

        RestoreCommunityPost ->
            "restore"

        HideSitePost ->
            "hide"

        UnhideSitePost ->
            "unhide"

        ImportSitePost ->
            "import"

        AcceptSubmission ->
            "accept"

        RejectSubmission ->
            "reject"

        BackfillDiscussion ->
            "backfill"


communityId : Route.Route -> String
communityId route =
    case route of
        Route.Community id ->
            id

        Route.NewTopic id ->
            id

        Route.Manage id ->
            id

        _ ->
            ""


type alias Model =
    { manage : Maybe ManageState, busy : Set String }


initial : Model
initial =
    { manage = Nothing, busy = Set.empty }


reset : Model -> Model
reset model =
    { model | manage = Nothing }

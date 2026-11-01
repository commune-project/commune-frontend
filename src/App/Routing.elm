module App.Routing exposing (loadRoute, loadSession, unreadCommand)

import Api
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Browser.Navigation as Navigation
import Domain
import Feature.AccountBlocks as AccountBlocks
import Feature.AccountContent as AccountContent
import Feature.Auth.State as AuthState
import Feature.Community as Community
import Feature.CommunityCreate as CommunityCreate
import Feature.CommunityManage.State as ManageState
import Feature.CommunityManage.Update as Manage
import Feature.Editor.State as EditorState exposing (EditorMode(..), emptyEditor)
import Feature.Editor.Update as Editor
import Feature.Feed as Feed
import Feature.Notifications as Notifications
import Feature.Post as Post
import Feature.Profile as Profile
import Feature.Report as Report
import Feature.Search as Search
import Feature.SiteAdmin.State as SiteAdminState
import Feature.SiteAdmin.Update as SiteAdmin
import Remote exposing (Remote(..))
import Route
import Url exposing (Url)


loadRoute : Model -> ( Model, Cmd Msg )
loadRoute model =
    let
        reset =
            { model
                | feed = Feed.initial
                , communityPage = Community.initial
                , posts = Post.reset model.posts
                , profile = Profile.reset model.profile
                , notificationsPage = Notifications.initial
                , editorPage = EditorState.initial
                , management = ManageState.reset model.management
                , accountContent = AccountContent.reset model.accountContent
                , accountBlocks = AccountBlocks.reset model.accountBlocks
                , report = Report.initial
                , siteAdmin = SiteAdminState.reset model.siteAdmin
            }

        epoch =
            model.routeEpoch
    in
    case model.route of
        Route.Latest ->
            let
                ( state, command ) =
                    Feed.load model.url
            in
            ( { reset | feed = state }, Cmd.map (FeedResponse epoch) command )

        Route.Communities ->
            loadCommunity reset

        Route.Community _ ->
            loadCommunity reset

        Route.Post id ->
            let
                ( state, command ) =
                    Post.load id model.url reset.posts
            in
            ( { reset | posts = state }, Cmd.map (PostResponse epoch) command )

        Route.NewCommunity ->
            ( { reset | communityCreate = CommunityCreate.initial }, Cmd.none )

        Route.NewTopic id ->
            loadCommunity { reset | editorPage = { editor = Just (emptyEditor (CreateTopic id)), source = NotAsked } }

        Route.EditPost id ->
            let
                ( state, command ) =
                    Editor.load id reset.editorPage
            in
            ( { reset | editorPage = state }, Cmd.map (EditorResponse epoch) command )

        Route.Search ->
            let
                ( state, command ) =
                    Search.load model.url
            in
            ( { reset | searchPage = state }, Cmd.map (SearchResponse epoch) command )

        Route.Notifications ->
            case model.auth of
                Authenticated _ ->
                    ( { reset | notificationsPage = { notifications = Loading, unreadCount = Nothing } }
                    , Cmd.map (NotificationsResponse epoch) (Notifications.load model.url)
                    )

                _ ->
                    ( reset, Cmd.none )

        Route.Profile username ->
            let
                ( state, command ) =
                    Profile.loadPublic username reset.profile
            in
            ( { reset | profile = state }, Cmd.map (ProfileResponse epoch) command )

        Route.Settings ->
            case model.auth of
                Authenticated _ ->
                    let
                        ( state, command ) =
                            Profile.loadOwn reset.profile
                    in
                    ( { reset | profile = state }, Cmd.map (ProfileResponse epoch) command )

                _ ->
                    ( reset, Cmd.none )

        Route.PasswordReset ->
            ( reset, Cmd.none )

        Route.PasswordResetConfirm ->
            let
                token =
                    model.url.fragment |> Maybe.withDefault ""

                withToken =
                    if String.isEmpty token then
                        reset

                    else
                        { reset | account = AuthState.withResetToken token reset.account }

                clean =
                    model.url

                cleanUrl =
                    Url.toString { clean | fragment = Nothing }
            in
            ( withToken
            , if String.isEmpty token then
                Cmd.none

              else
                Navigation.replaceUrl model.key cleanUrl
            )

        Route.PasswordSettings ->
            ( reset, Cmd.none )

        Route.AccountContent source ->
            case model.auth of
                Authenticated _ ->
                    let
                        ( state, command ) =
                            AccountContent.load source model.url reset.accountContent
                    in
                    ( { reset | accountContent = state }, Cmd.map (AccountContentResponse epoch) command )

                _ ->
                    ( reset, Cmd.none )

        Route.AccountBlocks ->
            case model.auth of
                Authenticated _ ->
                    let
                        ( state, command ) =
                            AccountBlocks.load reset.accountBlocks
                    in
                    ( { reset | accountBlocks = state }, Cmd.map (AccountBlocksResponse epoch) command )

                _ ->
                    ( reset, Cmd.none )

        Route.AdminOverview ->
            adminRoute model reset Route.AdminOverview

        Route.AdminSettings ->
            adminRoute model reset Route.AdminSettings

        Route.AdminReports ->
            adminRoute model reset Route.AdminReports

        Route.AdminModlog ->
            adminRoute model reset Route.AdminModlog

        Route.AdminBans ->
            adminRoute model reset Route.AdminBans

        Route.Manage id ->
            case model.auth of
                Authenticated _ ->
                    let
                        initial =
                            let
                                empty =
                                    ManageState.emptyManage
                            in
                            { empty
                                | community = Loading
                                , members = Loading
                                , managers = Loading
                                , followRequests = Loading
                                , reports = Loading
                                , modlog = Loading
                            }

                        ( state, command ) =
                            Manage.load id initial reset.management
                    in
                    ( { reset | management = state }, Cmd.map (ManageResponse epoch) command )

                _ ->
                    ( reset, Cmd.none )

        _ ->
            ( reset, Cmd.none )


adminRoute : Model -> Model -> Route.Route -> ( Model, Cmd Msg )
adminRoute original reset route =
    case original.auth of
        Authenticated identity ->
            if identity.siteAdmin || identity.deploymentAdmin then
                let
                    ( state, command ) =
                        case route of
                            Route.AdminSettings ->
                                SiteAdmin.loadSettings reset.siteAdmin

                            Route.AdminReports ->
                                SiteAdmin.loadReports original.url reset.siteAdmin

                            Route.AdminModlog ->
                                SiteAdmin.loadModlog original.url reset.siteAdmin

                            Route.AdminBans ->
                                SiteAdmin.loadBans reset.siteAdmin

                            _ ->
                                ( reset.siteAdmin, Cmd.none )
                in
                ( { reset | siteAdmin = state }, Cmd.map (SiteAdminResponse original.routeEpoch) command )

            else
                ( reset, Cmd.none )

        _ ->
            ( reset, Cmd.none )


loadCommunity : Model -> ( Model, Cmd Msg )
loadCommunity model =
    let
        ( state, command ) =
            Community.load model.route model.url model.communityPage
    in
    ( { model | communityPage = state }, Cmd.map (CommunityResponse model.routeEpoch) command )


unreadCommand : Model -> Cmd Msg
unreadCommand model =
    case model.auth of
        Authenticated _ ->
            Cmd.map (NotificationsResponse model.routeEpoch) Notifications.unread

        _ ->
            Cmd.none


loadSession : Model -> Cmd Msg
loadSession model =
    Api.get "/api/v1/auth/session"
        (SessionLoaded model.authGeneration << Api.decodeResponse Domain.identity)

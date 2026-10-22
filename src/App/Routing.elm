module App.Routing exposing (loadRoute, loadSession, unreadCommand)

import Api
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Domain
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
import Feature.Search as Search
import Remote exposing (Remote(..))
import Route


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

        Route.Manage id ->
            case model.auth of
                Authenticated _ ->
                    let
                        initial =
                            let
                                empty =
                                    ManageState.emptyManage
                            in
                            { empty | community = Loading, members = Loading, managers = Loading }

                        ( state, command ) =
                            Manage.load id initial reset.management
                    in
                    ( { reset | management = state }, Cmd.map (ManageResponse epoch) command )

                _ ->
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

module App.Features exposing (updateAuth, updateCommunity, updateCommunityCreate, updateEditor, updateFeed, updateManage, updateNotifications, updatePost, updateProfile, updateSearch)

import App.Access exposing (authProblem, clearPrivate)
import App.Feedback exposing (Flash(..))
import App.Interaction exposing (applyLike)
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Browser.Navigation as Navigation
import Feature.Auth.Update as Auth
import Feature.Community as Community
import Feature.CommunityCreate as CommunityCreate
import Feature.CommunityManage.Update as Manage
import Feature.Editor.Update as Editor
import Feature.Feed as Feed
import Feature.Notifications as Notifications
import Feature.Post as Post
import Feature.Profile as Profile
import Feature.Search as Search
import Ports exposing (requestCsrf)


updateEditor : Editor.Msg -> Model -> ( Model, Cmd Msg )
updateEditor message model =
    let
        ( state, command, outcome ) =
            Editor.update model.csrf message model.editorPage

        base =
            case outcome.sessionProblem of
                Just problem ->
                    authProblem model problem

                Nothing ->
                    model

        changed =
            { base
                | flash =
                    if outcome.flash == NoFlash then
                        base.flash

                    else
                        outcome.flash
                , editorPage = state
            }

        navigation =
            case outcome.navigation of
                Just target ->
                    Navigation.pushUrl model.key target

                Nothing ->
                    Cmd.none
    in
    ( changed, Cmd.batch [ Cmd.map (EditorResponse model.routeEpoch) command, navigation ] )


updateManage : Manage.Msg -> Model -> ( Model, Cmd Msg )
updateManage message model =
    let
        ( state, command, outcome ) =
            Manage.update { csrf = model.csrf, route = model.route } message model.management

        base =
            case outcome.sessionProblem of
                Just problem ->
                    authProblem model problem

                Nothing ->
                    model
    in
    ( { base
        | flash =
            if outcome.flash == NoFlash then
                base.flash

            else
                outcome.flash
        , management =
            (\managementState ->
                { managementState
                    | manage = state.manage
                    , busy =
                        if outcome.sessionProblem == Nothing then
                            state.busy

                        else
                            base.management.busy
                }
            )
                base.management
      }
    , Cmd.map (ManageResponse model.routeEpoch) command
    )


updateAuth : Auth.Msg -> Model -> ( Model, Cmd Msg )
updateAuth message model =
    let
        ( state, command, outcome ) =
            Auth.update model.csrf message model.account

        changed =
            { model
                | flash =
                    if outcome.flash == NoFlash then
                        model.flash

                    else
                        outcome.flash
                , account = state
            }

        ( session, navigation ) =
            case outcome.identity of
                Just identity ->
                    ( { changed | auth = Authenticated identity, authGeneration = changed.authGeneration + 1, routeEpoch = changed.routeEpoch + 1, flash = NoFlash }
                    , Cmd.batch [ Navigation.pushUrl model.key "/", requestCsrf ]
                    )

                Nothing ->
                    if outcome.loggedOut then
                        ( clearPrivate { changed | auth = Anonymous, authGeneration = changed.authGeneration + 1, routeEpoch = changed.routeEpoch + 1, csrf = "" }
                        , Cmd.batch [ Navigation.pushUrl model.key "/login", requestCsrf ]
                        )

                    else
                        ( changed, Cmd.none )
    in
    ( session, Cmd.batch [ Cmd.map (AuthResponse model.routeEpoch) command, navigation ] )


updateProfile : Profile.Msg -> Model -> ( Model, Cmd Msg )
updateProfile message model =
    let
        ( state, command, outcome ) =
            Profile.update model.csrf message model.profile

        base =
            case outcome.sessionProblem of
                Just problem ->
                    authProblem model problem

                Nothing ->
                    model
    in
    ( { base
        | flash =
            if outcome.flash == NoFlash then
                base.flash

            else
                outcome.flash
        , profile =
            (\profileState ->
                { profileState
                    | publicProfile = state.publicProfile
                    , ownProfile = state.ownProfile
                    , profileForm =
                        if outcome.sessionProblem == Nothing then
                            state.profileForm

                        else
                            base.profile.profileForm
                }
            )
                base.profile
      }
    , Cmd.map (ProfileResponse model.routeEpoch) command
    )


updateSearch : Search.Msg -> Model -> ( Model, Cmd Msg )
updateSearch message model =
    let
        ( state, command, outcome ) =
            Search.update message model.searchPage

        base =
            case outcome.sessionProblem of
                Just problem ->
                    authProblem model problem

                Nothing ->
                    model

        navigation =
            case outcome.navigation of
                Just target ->
                    Navigation.pushUrl model.key target

                Nothing ->
                    Cmd.none
    in
    ( { base | searchPage = state }, Cmd.batch [ Cmd.map (SearchResponse model.routeEpoch) command, navigation ] )


updateNotifications : Notifications.Msg -> Model -> ( Model, Cmd Msg )
updateNotifications message model =
    let
        ( state, command, outcome ) =
            Notifications.update model.csrf model.url message model.notificationsPage

        base =
            case outcome.sessionProblem of
                Just problem ->
                    authProblem model problem

                Nothing ->
                    model
    in
    ( { base
        | flash =
            if outcome.flash == NoFlash then
                base.flash

            else
                outcome.flash
        , notificationsPage =
            (\notificationsPageState ->
                { notificationsPageState
                    | notifications =
                        if outcome.sessionProblem == Nothing then
                            state.notifications

                        else
                            case message of
                                Notifications.Loaded _ ->
                                    state.notifications

                                _ ->
                                    base.notificationsPage.notifications
                    , unreadCount =
                        if outcome.sessionProblem == Nothing then
                            state.unreadCount

                        else
                            base.notificationsPage.unreadCount
                }
            )
                base.notificationsPage
      }
    , Cmd.map (NotificationsResponse model.routeEpoch) command
    )


updateCommunityCreate : CommunityCreate.Msg -> Model -> ( Model, Cmd Msg )
updateCommunityCreate message model =
    let
        ( state, command, outcome ) =
            CommunityCreate.update model.csrf message model.communityCreate

        navigation =
            case outcome.navigation of
                Just target ->
                    Navigation.pushUrl model.key target

                Nothing ->
                    Cmd.none
    in
    ( { model
        | flash =
            if outcome.flash == NoFlash then
                model.flash

            else
                outcome.flash
        , communityCreate = state
      }
    , Cmd.batch [ Cmd.map (CommunityCreateResponse model.routeEpoch) command, navigation ]
    )


updatePost : Post.Msg -> Model -> ( Model, Cmd Msg )
updatePost message model =
    let
        ( state, command, outcome ) =
            Post.update model.csrf message model.posts

        base =
            case outcome.sessionProblem of
                Just problem ->
                    authProblem model problem

                Nothing ->
                    model

        changed =
            { base
                | flash =
                    if outcome.flash == NoFlash then
                        base.flash

                    else
                        outcome.flash
                , posts =
                    (\postsState ->
                        { postsState
                            | post = state.post
                            , replies = state.replies
                            , nestedReplies = state.nestedReplies
                            , expandedReplies = state.expandedReplies
                            , busy =
                                if outcome.sessionProblem == Nothing then
                                    state.busy

                                else
                                    base.posts.busy
                        }
                    )
                        base.posts
            }

        liked =
            case outcome.like of
                Just ( id, wasLiked ) ->
                    applyLike id wasLiked changed

                Nothing ->
                    changed

        navigation =
            case outcome.navigation of
                Just target ->
                    Navigation.pushUrl model.key target

                Nothing ->
                    Cmd.none
    in
    ( liked, Cmd.batch [ Cmd.map (PostResponse model.routeEpoch) command, navigation ] )


updateFeed : Feed.Msg -> Model -> ( Model, Cmd Msg )
updateFeed message model =
    let
        ( state, problem ) =
            Feed.update message model.feed

        base =
            case problem of
                Just failure ->
                    authProblem model failure

                Nothing ->
                    model
    in
    ( { base | feed = state }, Cmd.none )


updateCommunity : Community.Msg -> Model -> ( Model, Cmd Msg )
updateCommunity message model =
    let
        ( state, problem ) =
            Community.update message model.communityPage

        base =
            case problem of
                Just failure ->
                    authProblem model failure

                Nothing ->
                    model
    in
    ( { base | communityPage = state }, Cmd.none )

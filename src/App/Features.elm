module App.Features exposing (updateAccountBlocks, updateAccountContent, updateAuth, updateCommunity, updateCommunityCreate, updateEditor, updateFeed, updateManage, updateNotifications, updatePost, updateProfile, updateReport, updateSearch, updateSiteAdmin)

import Api
import App.Access exposing (authProblem, clearPrivate)
import App.Feedback exposing (Flash(..))
import App.Interaction exposing (applyPost)
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Browser.Navigation as Navigation
import Domain
import Feature.AccountBlocks as AccountBlocks
import Feature.AccountContent as AccountContent
import Feature.Auth.Update as Auth
import Feature.Community as Community
import Feature.CommunityCreate as CommunityCreate
import Feature.CommunityManage.Update as Manage
import Feature.Editor.Update as Editor
import Feature.Feed as Feed
import Feature.Notifications as Notifications
import Feature.Post as Post
import Feature.Profile as Profile
import Feature.Report as Report
import Feature.Search as Search
import Feature.SiteAdmin.Update as SiteAdmin
import Ports exposing (closeDialog, focus, openDialog, requestCsrf)
import Remote exposing (Remote(..))
import Url


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


updateAccountContent : AccountContent.Msg -> Model -> ( Model, Cmd Msg )
updateAccountContent message model =
    let
        ( state, problem ) =
            AccountContent.update message model.accountContent

        base =
            case problem of
                Just failure ->
                    authProblem model failure

                Nothing ->
                    model
    in
    ( { base | accountContent = state }, Cmd.none )


updateAccountBlocks : AccountBlocks.Msg -> Model -> ( Model, Cmd Msg )
updateAccountBlocks message model =
    let
        ( state, command, outcome ) =
            AccountBlocks.update model.csrf message model.accountBlocks

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
        , accountBlocks = state
      }
    , Cmd.map (AccountBlocksResponse model.routeEpoch) command
    )


updateReport : Report.Msg -> Model -> ( Model, Cmd Msg )
updateReport message model =
    let
        ( state, command, outcome ) =
            Report.update model.csrf message model.report

        base =
            case outcome.sessionProblem of
                Just problem ->
                    authProblem model problem

                Nothing ->
                    model

        dialogCommand =
            case outcome.dialog of
                Just Report.OpenDialog ->
                    openDialog "report-dialog"

                Just Report.CloseDialog ->
                    Cmd.batch [ closeDialog "report-dialog", focus "main-heading" ]

                Nothing ->
                    Cmd.none
    in
    ( { base
        | flash =
            if outcome.flash == NoFlash then
                base.flash

            else
                outcome.flash
        , report = state
      }
    , Cmd.batch [ Cmd.map (ReportResponse model.routeEpoch) command, dialogCommand ]
    )


updateSiteAdmin : SiteAdmin.Msg -> Model -> ( Model, Cmd Msg )
updateSiteAdmin message model =
    let
        ( state, command, outcome ) =
            SiteAdmin.update { csrf = model.csrf, url = model.url } message model.siteAdmin

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

        refresh =
            if outcome.refreshModlog then
                let
                    ( _, refreshCommand ) =
                        SiteAdmin.loadModlog model.url state
                in
                Cmd.batch
                    [ refreshCommand |> Cmd.map (SiteAdminResponse model.routeEpoch)
                    ]

            else
                Cmd.none
    in
    ( { base
        | flash =
            if outcome.flash == NoFlash then
                base.flash

            else
                outcome.flash
        , siteAdmin = state
      }
    , Cmd.batch [ Cmd.map (SiteAdminResponse model.routeEpoch) command, navigation, refresh ]
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
                    ( { changed
                        | auth = Authenticated identity
                        , drawerProfile = Loading
                        , authGeneration = changed.authGeneration + 1
                        , routeEpoch = changed.routeEpoch + 1
                        , flash = NoFlash
                      }
                    , Cmd.batch
                        [ Navigation.pushUrl model.key "/"
                        , requestCsrf
                        , Api.get "/api/v1/profile" (DrawerProfileLoaded << Api.decodeResponse Domain.profile)
                        ]
                    )

                Nothing ->
                    if outcome.loggedOut then
                        ( clearPrivate { changed | auth = Anonymous, authGeneration = changed.authGeneration + 1, routeEpoch = changed.routeEpoch + 1, csrf = "" }
                        , Cmd.batch [ Navigation.pushUrl model.key "/login", requestCsrf ]
                        )

                    else
                        ( changed
                        , case outcome.navigation of
                            Just target ->
                                Navigation.pushUrl model.key target

                            Nothing ->
                                Cmd.none
                        )
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
            Post.update model.csrf model.url message model.posts

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

        applied =
            case outcome.refreshed of
                Just post ->
                    applyPost post changed

                Nothing ->
                    changed

        navigation =
            case outcome.navigation of
                Just target ->
                    Navigation.pushUrl model.key target

                Nothing ->
                    Cmd.none

        reload =
            if outcome.reloadRoute then
                Navigation.pushUrl model.key (Url.toString model.url)

            else
                Cmd.none
    in
    ( applied, Cmd.batch [ Cmd.map (PostResponse model.routeEpoch) command, navigation, reload ] )


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
        ( state, command, outcome ) =
            Community.update model.csrf message model.communityPage

        base =
            case outcome.sessionProblem of
                Just failure ->
                    authProblem model failure

                Nothing ->
                    model
    in
    ( { base
        | communityPage = state
        , flash =
            if outcome.flash == NoFlash then
                base.flash

            else
                outcome.flash
      }
    , Cmd.map (CommunityResponse model.routeEpoch) command
    )

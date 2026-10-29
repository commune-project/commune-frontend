module Main exposing (main)

import Api
import App.Access exposing (authProblem)
import App.Browser exposing (receiveIncoming)
import App.Features exposing (updateAuth, updateCommunity, updateCommunityCreate, updateEditor, updateFeed, updateManage, updateNotifications, updatePost, updateProfile, updateSearch)
import App.Feedback exposing (Flash(..))
import App.Init exposing (init)
import App.Localization exposing (beginStartup, resolveCatalog, selectLocale)
import App.Routing exposing (loadRoute, unreadCommand)
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import App.View exposing (view)
import Browser
import Browser.Navigation as Navigation
import Domain
import Feature.Auth.Update as Auth
import Feature.Post as Post
import Json.Decode as Decode
import Locale exposing (Locale(..))
import Ports exposing (closeDialog, focus, incoming, openDialog)
import Remote exposing (Remote(..))
import Route
import Ui.PostCard exposing (deleteTriggerId)
import Url exposing (Url)


main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = Navigate
        , onUrlChange = UrlChanged
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Navigate request ->
            case request of
                Browser.Internal url ->
                    ( model, Navigation.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Navigation.load href )

        UrlChanged url ->
            let
                changed =
                    { model
                        | url = url
                        , route = Route.parse url
                        , routeEpoch = model.routeEpoch + 1
                        , drawerOpen =
                            if model.wideLayout then
                                model.drawerOpen

                            else
                                False
                        , dialog = Nothing
                    }

                ( loaded, command ) =
                    loadRoute changed
            in
            ( loaded, Cmd.batch [ command, unreadCommand loaded, closeDialog "navigation-drawer", focus "main-heading" ] )

        LanguageSelected raw ->
            selectLocale raw model

        BootLanguageSelected raw ->
            case Locale.fromString raw of
                Just target ->
                    beginStartup target model

                Nothing ->
                    ( model, Cmd.none )

        RetryLocalization ->
            beginStartup model.requested model

        RetryPage ->
            let
                ( loaded, command ) =
                    loadRoute { model | routeEpoch = model.routeEpoch + 1 }
            in
            ( loaded, Cmd.batch [ command, unreadCommand loaded ] )

        CatalogResult request result ->
            resolveCatalog request result model

        Incoming value ->
            receiveIncoming value model

        SessionLoaded generation result ->
            if generation /= model.authGeneration then
                ( model, Cmd.none )

            else
                let
                    changed =
                        case result of
                            Ok identity ->
                                { model | auth = Authenticated identity, drawerProfile = Loading }

                            Err problem ->
                                { model
                                    | auth = Anonymous
                                    , drawerProfile = NotAsked
                                    , flash =
                                        if problem.status == 401 then
                                            model.flash

                                        else
                                            FlashProblem problem
                                }

                    ( loaded, command ) =
                        loadRoute changed
                in
                ( loaded, Cmd.batch [ command, unreadCommand loaded, loadDrawerProfile changed ] )

        DrawerProfileLoaded result ->
            case model.auth of
                Authenticated _ ->
                    case result of
                        Ok profile ->
                            ( { model | drawerProfile = Ready profile }, Cmd.none )

                        Err problem ->
                            if problem.status == 401 then
                                ( authProblem model problem, Cmd.none )

                            else
                                ( { model | drawerProfile = Failed problem }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        OpenDrawer ->
            if model.wideLayout then
                ( { model | drawerOpen = True }, Cmd.none )

            else
                ( { model | drawerOpen = True }, openDialog "navigation-drawer" )

        CloseDrawer ->
            if model.wideLayout then
                ( { model | drawerOpen = False }, focus "menu-button" )

            else
                ( { model | drawerOpen = False }, Cmd.batch [ closeDialog "navigation-drawer", focus "menu-button" ] )

        DrawerClosed ->
            ( { model | drawerOpen = False }, Cmd.none )

        OpenDeleteDialog id ->
            ( { model | dialog = Just id }, openDialog "confirmation-dialog" )

        CloseDialog ->
            ( { model | dialog = Nothing }
            , Cmd.batch
                [ closeDialog "confirmation-dialog"
                , focus (deleteTriggerId (Maybe.withDefault "" model.dialog))
                ]
            )

        ConfirmDelete id ->
            let
                ( changed, command ) =
                    updatePost (Post.ConfirmDelete id) { model | dialog = Nothing, flash = NoFlash }
            in
            ( changed, Cmd.batch [ command, closeDialog "confirmation-dialog" ] )

        Noop ->
            ( model, Cmd.none )

        EditorMessage event ->
            updateEditor event model

        EditorResponse epoch event ->
            if epoch == model.routeEpoch then
                updateEditor event model

            else
                ( model, Cmd.none )

        ManageMessage event ->
            updateManage event model

        ManageResponse epoch event ->
            if epoch == model.routeEpoch then
                updateManage event model

            else
                ( model, Cmd.none )

        AuthMessage event ->
            updateAuth event model

        AuthResponse epoch event ->
            if epoch == model.routeEpoch || Auth.isSessionAction event then
                updateAuth event model

            else
                ( model, Cmd.none )

        ProfileMessage event ->
            updateProfile event model

        ProfileResponse epoch event ->
            if epoch == model.routeEpoch then
                updateProfile event model

            else
                ( model, Cmd.none )

        SearchMessage event ->
            updateSearch event model

        SearchResponse epoch event ->
            if epoch == model.routeEpoch then
                updateSearch event model

            else
                ( model, Cmd.none )

        NotificationsMessage event ->
            updateNotifications event model

        NotificationsResponse epoch event ->
            if epoch == model.routeEpoch then
                updateNotifications event model

            else
                ( model, Cmd.none )

        CommunityCreateMessage event ->
            updateCommunityCreate event model

        CommunityCreateResponse epoch event ->
            if epoch == model.routeEpoch then
                updateCommunityCreate event model

            else
                ( model, Cmd.none )

        PostMessage event ->
            updatePost event model

        PostResponse epoch event ->
            if epoch == model.routeEpoch then
                updatePost event model

            else
                ( model, Cmd.none )

        FeedResponse epoch event ->
            if epoch == model.routeEpoch then
                updateFeed event model

            else
                ( model, Cmd.none )

        CommunityResponse epoch event ->
            if epoch == model.routeEpoch then
                updateCommunity event model

            else
                ( model, Cmd.none )

        DismissFlash ->
            ( { model | flash = NoFlash }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    incoming Incoming


loadDrawerProfile : Model -> Cmd Msg
loadDrawerProfile model =
    case model.auth of
        Authenticated _ ->
            Api.get "/api/v1/profile" (DrawerProfileLoaded << Api.decodeResponse Domain.profile)

        _ ->
            Cmd.none

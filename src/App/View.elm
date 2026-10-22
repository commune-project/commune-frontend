module App.View exposing (view)

import App.Context exposing (Active)
import App.Shell exposing (viewBoot, viewReady)
import App.State exposing (Model, Msg(..))
import App.View.Account exposing (pageLogin, pagePublicProfile, pageRegister, pageSettings, pageVerify)
import App.View.Content exposing (editorConfig, pageCommunities, pageCommunity, pageLatest, pagePost, pageSearch)
import App.View.Participation exposing (pageManage, pageNewCommunity, pageNotifications)
import Browser
import Feature.Editor.State exposing (EditorMode(..))
import Feature.Editor.Update as Editor
import Feature.Editor.View
import Generated.I18n as Translations
import Html exposing (Html, p, text)
import Remote exposing (Remote(..))
import Route
import Ui.Layout exposing (pageHeading)


view : Model -> Browser.Document Msg
view model =
    let
        title =
            case model.active of
                Nothing ->
                    "Commune"

                Just active ->
                    let
                        appName =
                            Translations.appTitle active.texts

                        pageName =
                            routeTitle model active
                    in
                    if String.isEmpty appName then
                        pageName

                    else if String.isEmpty pageName || pageName == appName then
                        appName

                    else
                        pageName ++ " · " ++ appName
    in
    { title = title
    , body =
        [ case model.active of
            Nothing ->
                viewBoot model

            Just active ->
                viewReady (pageView model active) model active
        ]
    }


routeTitle : Model -> Active -> String
routeTitle model active =
    let
        texts =
            active.texts
    in
    case model.route of
        Route.Latest ->
            Translations.latestTitle texts

        Route.Communities ->
            Translations.communitiesTitle texts

        Route.Community _ ->
            case model.communityPage.community of
                Ready community ->
                    community.title

                _ ->
                    Translations.communitiesTitle texts

        Route.Post _ ->
            case model.posts.post of
                Ready post ->
                    if String.isEmpty post.title then
                        Translations.repliesTitle texts

                    else
                        post.title

                _ ->
                    Translations.repliesTitle texts

        Route.NewCommunity ->
            Translations.createCommunity texts

        Route.NewTopic _ ->
            Translations.publishTopic texts

        Route.EditPost _ ->
            Translations.editPost texts

        Route.Login ->
            Translations.loginTitle texts

        Route.Register ->
            Translations.registerTitle texts

        Route.Verify ->
            Translations.verifyTitle texts

        Route.Search ->
            Translations.searchTitle texts

        Route.Notifications ->
            Translations.notificationsTitle texts

        Route.Profile _ ->
            Translations.profileTitle texts

        Route.Settings ->
            Translations.settingsTitle texts

        Route.Manage _ ->
            Translations.manageTitle texts

        Route.NotFound ->
            Translations.notFound texts


pageView : Model -> Active -> Html Msg
pageView model active =
    case model.route of
        Route.Latest ->
            pageLatest model active

        Route.Communities ->
            pageCommunities model active

        Route.Community id ->
            pageCommunity model active id

        Route.Post id ->
            pagePost model active id

        Route.NewCommunity ->
            pageNewCommunity model active

        Route.NewTopic id ->
            Feature.Editor.View.pageEditor (editorConfig model) { editor = model.editorPage.editor, source = model.editorPage.source } active (CreateTopic id)

        Route.EditPost id ->
            Feature.Editor.View.pageEditor (editorConfig model) { editor = model.editorPage.editor, source = model.editorPage.source } active (EditPost id)

        Route.Login ->
            pageLogin model active

        Route.Register ->
            pageRegister model active

        Route.Verify ->
            pageVerify model active

        Route.Search ->
            pageSearch model active

        Route.Notifications ->
            pageNotifications model active

        Route.Profile username ->
            pagePublicProfile model active username

        Route.Settings ->
            pageSettings model active

        Route.Manage id ->
            pageManage model active id

        Route.NotFound ->
            pageHeading (Translations.notFound active.texts)
                (p [] [ text (Translations.notFound active.texts) ])

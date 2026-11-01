module App.View exposing (view)

import App.Context exposing (Active)
import App.Shell exposing (viewBoot, viewReady)
import App.State exposing (ConfirmationAction(..), Model, Msg(..))
import App.View.Account exposing (pageLogin, pagePasswordReset, pagePasswordResetConfirm, pagePasswordSettings, pagePublicProfile, pageRegister, pageSettings, pageVerify)
import App.View.Content exposing (editorConfig, pageCommunities, pageCommunity, pageLatest, pagePost, pageSearch, postCard)
import App.View.Participation exposing (pageManage, pageNewCommunity, pageNotifications)
import Browser
import Domain
import Feature.AccountBlocks as AccountBlocks
import Feature.AccountContent as AccountContent
import Feature.Editor.State exposing (EditorMode(..))
import Feature.Editor.Update as Editor
import Feature.Editor.View
import Feature.Report as Report
import Feature.SiteAdmin.Update as SiteAdmin
import Feature.SiteAdmin.View as SiteAdminView
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
                viewReady (pageView model active) (reportDialog model active) model active
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

        Route.PasswordReset ->
            Translations.resetPasswordTitle texts

        Route.PasswordResetConfirm ->
            Translations.resetPasswordTitle texts

        Route.PasswordSettings ->
            Translations.changePasswordTitle texts

        Route.AccountContent source ->
            accountContentTitle texts source

        Route.AccountBlocks ->
            Translations.blockTitle texts

        Route.AdminOverview ->
            Translations.adminTitle texts

        Route.AdminReports ->
            Translations.reportsTitle texts

        Route.AdminModlog ->
            Translations.modlogTitle texts

        Route.AdminBans ->
            Translations.banTitle texts

        Route.AdminSettings ->
            Translations.voteSettingsTitle texts

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

        Route.PasswordReset ->
            pagePasswordReset model active

        Route.PasswordResetConfirm ->
            pagePasswordResetConfirm model active

        Route.PasswordSettings ->
            pagePasswordSettings model active

        Route.AccountContent source ->
            AccountContent.pageAccountContent
                { retry = RetryPage, postCard = postCard model active }
                { posts = model.accountContent.posts, auth = model.auth, url = model.url }
                active
                source

        Route.AccountBlocks ->
            AccountBlocks.pageAccountBlocks
                (accountBlocksConfig model)
                { blocks = model.accountBlocks.blocks
                , kind = model.accountBlocks.kind
                , target = model.accountBlocks.target
                , busy = model.accountBlocks.busy
                , problem = model.accountBlocks.problem
                , auth = model.auth
                }
                active

        Route.AdminOverview ->
            SiteAdminView.pageOverview (siteAdminConfig model) (siteAdminViewModel model) active

        Route.AdminReports ->
            SiteAdminView.pageReports (siteAdminConfig model) (siteAdminViewModel model) active

        Route.AdminModlog ->
            SiteAdminView.pageModlog (siteAdminConfig model) (siteAdminViewModel model) active

        Route.AdminBans ->
            SiteAdminView.pageBans (siteAdminConfig model) (siteAdminViewModel model) active

        Route.AdminSettings ->
            SiteAdminView.pageSettings (siteAdminConfig model) (siteAdminViewModel model) active

        Route.Manage id ->
            pageManage model active id

        Route.NotFound ->
            pageHeading (Translations.notFound active.texts)
                (p [] [ text (Translations.notFound active.texts) ])


accountContentTitle : Translations.I18n -> Domain.AccountContentSource -> String
accountContentTitle texts source =
    case source of
        Domain.SavedContent ->
            Translations.savedPostsTitle texts

        Domain.ReadContent ->
            Translations.readPostsTitle texts

        Domain.HiddenContent ->
            Translations.hiddenPostsTitle texts

        Domain.LikedContent ->
            Translations.likedPostsTitle texts


accountBlocksConfig : Model -> AccountBlocks.Config Msg
accountBlocksConfig model =
    { retry = RetryPage
    , kindChanged = AccountBlocksMessage << AccountBlocks.KindChanged
    , targetChanged = AccountBlocksMessage << AccountBlocks.TargetChanged
    , addBlock = AccountBlocksMessage AccountBlocks.AddBlock
    , confirmRemoveBlock = \kind target -> OpenConfirmation (RemoveBlockDialog kind target)
    , formatted = model.formatted
    }


siteAdminConfig : Model -> SiteAdminView.Config Msg
siteAdminConfig _ =
    { retry = RetryPage
    , upvotesChanged = SiteAdminMessage << SiteAdmin.UpvotesChanged
    , downvotesChanged = SiteAdminMessage << SiteAdmin.DownvotesChanged
    , saveSettings = SiteAdminMessage SiteAdmin.SaveSettings
    , reportStateChanged = SiteAdminMessage << SiteAdmin.ReportStateChanged
    , reportCommunityChanged = SiteAdminMessage << SiteAdmin.ReportCommunityChanged
    , applyReportFilter = SiteAdminMessage SiteAdmin.ApplyReportFilter
    , reportNoteChanged = \id value -> SiteAdminMessage (SiteAdmin.ReportNoteChanged id value)
    , confirmResolveReport = \id state -> OpenConfirmation (ResolveReportDialog id state)
    , modlogCommunityChanged = SiteAdminMessage << SiteAdmin.ModlogCommunityChanged
    , applyModlogFilter = SiteAdminMessage SiteAdmin.ApplyModlogFilter
    , banActorChanged = SiteAdminMessage << SiteAdmin.BanActorChanged
    , banReasonChanged = SiteAdminMessage << SiteAdmin.BanReasonChanged
    , banExpiresChanged = SiteAdminMessage << SiteAdmin.BanExpiresChanged
    , createBan = SiteAdminMessage SiteAdmin.CreateBan
    , confirmRemoveBan = OpenConfirmation RemoveSiteBanDialog
    }


siteAdminViewModel : Model -> SiteAdminView.ViewModel
siteAdminViewModel model =
    { admin = model.siteAdmin
    , auth = model.auth
    , formatted = model.formatted
    , url = model.url
    }


reportDialog : Model -> Active -> Html Msg
reportDialog model active =
    Report.reportDialog
        { close = ReportMessage Report.Close
        , reasonChanged = ReportMessage << Report.ReasonChanged
        , submit = ReportMessage Report.Submit
        }
        model.report
        active

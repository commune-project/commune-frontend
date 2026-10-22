module App.View.Participation exposing (pageManage, pageNewCommunity, pageNotifications)

import App.Context exposing (Active)
import App.State exposing (Model, Msg(..))
import Feature.CommunityCreate as CommunityCreate
import Feature.CommunityManage.State exposing (ManagePostAction(..))
import Feature.CommunityManage.Update as Manage
import Feature.CommunityManage.View
import Feature.Notifications as Notifications
import Html exposing (Html)


pageManage : Model -> Active -> String -> Html Msg
pageManage model active id =
    Feature.CommunityManage.View.pageManage
        { retry = RetryPage
        , manageActorChanged = ManageMessage << Manage.ManageActorChanged
        , managePostChanged = ManageMessage << Manage.ManagePostChanged
        , manageContextChanged = ManageMessage << Manage.ManageContextChanged
        , manageReadChanged = ManageMessage << Manage.ManageReadChanged
        , managePostPolicyChanged = ManageMessage << Manage.ManagePostPolicyChanged
        , manageApplyPolicy = ManageMessage Manage.ManageApplyPolicy
        , manageAddMember = ManageMessage Manage.ManageAddMember
        , manageRemoveMember = ManageMessage << Manage.ManageRemoveMember
        , manageAddManager = ManageMessage Manage.ManageAddManager
        , manageRemoveManager = ManageMessage << Manage.ManageRemoveManager
        , managePreviousMembers = ManageMessage Manage.ManagePreviousMembers
        , manageNextMembers = ManageMessage Manage.ManageNextMembers
        , managePreviousManagers = ManageMessage Manage.ManagePreviousManagers
        , manageNextManagers = ManageMessage Manage.ManageNextManagers
        , managePostAction = \postId action -> ManageMessage (Manage.ManagePostAction postId action)
        }
        { auth = model.auth, manage = model.management.manage }
        active
        id


pageNotifications : Model -> Active -> Html Msg
pageNotifications model active =
    Notifications.pageNotifications (notificationsViewConfig model) { unreadCount = model.notificationsPage.unreadCount, notifications = model.notificationsPage.notifications, auth = model.auth, formatted = model.formatted, url = model.url } active


notificationsViewConfig : Model -> Notifications.Config Msg
notificationsViewConfig model =
    { retry = RetryPage
    , markNoticeRead = NotificationsMessage << Notifications.MarkNoticeRead
    , markAllNoticesRead = NotificationsMessage Notifications.MarkAllNoticesRead
    }


pageNewCommunity : Model -> Active -> Html Msg
pageNewCommunity model active =
    CommunityCreate.pageNewCommunity (communityCreateViewConfig model) { createCommunity = model.communityCreate.createCommunity, auth = model.auth } active


communityCreateViewConfig : Model -> CommunityCreate.Config Msg
communityCreateViewConfig model =
    { retry = RetryPage
    , communityNameChanged = CommunityCreateMessage << CommunityCreate.CommunityNameChanged
    , communityTitleChanged = CommunityCreateMessage << CommunityCreate.CommunityTitleChanged
    , communityModeChanged = CommunityCreateMessage << CommunityCreate.CommunityModeChanged
    , communityReadChanged = CommunityCreateMessage << CommunityCreate.CommunityReadChanged
    , communityPostChanged = CommunityCreateMessage << CommunityCreate.CommunityPostChanged
    , communityCreate = CommunityCreateMessage CommunityCreate.CommunityCreate
    }

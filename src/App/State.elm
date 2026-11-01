module App.State exposing (ConfirmationAction(..), Model, Msg(..))

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Browser
import Browser.Navigation as Navigation
import Domain
import Feature.AccountBlocks as AccountBlocks
import Feature.AccountContent as AccountContent
import Feature.Auth.State
import Feature.Auth.Update as Auth
import Feature.Community as Community
import Feature.CommunityCreate as CommunityCreate
import Feature.CommunityManage.State
import Feature.CommunityManage.Update as Manage
import Feature.Editor.State
import Feature.Editor.Update as Editor
import Feature.Feed as Feed
import Feature.Notifications as Notifications
import Feature.Post as Post
import Feature.Profile as Profile
import Feature.Report as Report
import Feature.Search as Search
import Feature.SiteAdmin.State
import Feature.SiteAdmin.Update as SiteAdmin
import Generated.I18n as Translations
import Http
import Json.Decode as Decode
import Locale exposing (Locale(..))
import Localization
import Remote exposing (Remote)
import Route
import Ui.Formatting exposing (Formatting)
import Url exposing (Url)


type alias Model =
    { key : Navigation.Key
    , url : Url
    , route : Route.Route
    , routeEpoch : Int
    , authGeneration : Int
    , auth : AuthState
    , csrf : String
    , active : Maybe Active
    , requested : Locale
    , bootFailed : Bool
    , loading : Localization.State
    , drawerOpen : Bool
    , wideLayout : Bool
    , drawerProfile : Remote Domain.Profile
    , dialog : Maybe ConfirmationAction
    , flash : Flash
    , formatted : Maybe Formatting
    , account : Feature.Auth.State.Model
    , editorPage : Feature.Editor.State.Model
    , management : Feature.CommunityManage.State.Model
    , accountContent : AccountContent.Model
    , accountBlocks : AccountBlocks.Model
    , report : Report.Model
    , siteAdmin : Feature.SiteAdmin.State.Model
    , profile : Profile.Model
    , searchPage : Search.Model
    , notificationsPage : Notifications.Model
    , communityCreate : CommunityCreate.Model
    , posts : Post.Model
    , communityPage : Community.Model
    , feed : Feed.Model
    }


type ConfirmationAction
    = DeletePostDialog String
    | ResolveReportDialog String String
    | RemoveSiteBanDialog
    | RemoveCommunityBanDialog
    | RemoveBlockDialog String String


type Msg
    = Navigate Browser.UrlRequest
    | UrlChanged Url
    | LanguageSelected String
    | BootLanguageSelected String
    | RetryLocalization
    | RetryPage
    | CatalogResult Localization.Pending (Result Http.Error (Translations.I18n -> Translations.I18n))
    | Incoming Decode.Value
    | SessionLoaded Int (Result Api.Problem Domain.Identity)
    | DrawerProfileLoaded (Result Api.Problem Domain.Profile)
    | OpenDrawer
    | CloseDrawer
    | DrawerClosed
    | OpenDeleteDialog String
    | OpenConfirmation ConfirmationAction
    | CloseDialog
    | ConfirmDialog
    | Noop
    | EditorMessage Editor.Msg
    | EditorResponse Int Editor.Msg
    | ManageMessage Manage.Msg
    | ManageResponse Int Manage.Msg
    | AccountContentMessage AccountContent.Msg
    | AccountContentResponse Int AccountContent.Msg
    | AccountBlocksMessage AccountBlocks.Msg
    | AccountBlocksResponse Int AccountBlocks.Msg
    | ReportMessage Report.Msg
    | ReportResponse Int Report.Msg
    | SiteAdminMessage SiteAdmin.Msg
    | SiteAdminResponse Int SiteAdmin.Msg
    | AuthMessage Auth.Msg
    | AuthResponse Int Auth.Msg
    | ProfileMessage Profile.Msg
    | ProfileResponse Int Profile.Msg
    | SearchMessage Search.Msg
    | SearchResponse Int Search.Msg
    | NotificationsMessage Notifications.Msg
    | NotificationsResponse Int Notifications.Msg
    | CommunityCreateMessage CommunityCreate.Msg
    | CommunityCreateResponse Int CommunityCreate.Msg
    | PostMessage Post.Msg
    | PostResponse Int Post.Msg
    | FeedResponse Int Feed.Msg
    | CommunityMessage Community.Msg
    | CommunityResponse Int Community.Msg
    | DismissFlash

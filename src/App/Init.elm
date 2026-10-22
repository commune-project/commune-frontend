module App.Init exposing (init)

import App.Feedback exposing (Flash(..))
import App.Localization exposing (loadCatalog)
import App.Routing exposing (loadSession)
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Browser.Navigation as Navigation
import Feature.Auth.State
import Feature.Auth.Update as Auth
import Feature.Community as Community
import Feature.CommunityCreate as CommunityCreate
import Feature.CommunityManage.State
import Feature.Editor.State
import Feature.Editor.Update as Editor
import Feature.Feed as Feed
import Feature.Notifications as Notifications
import Feature.Post as Post
import Feature.Profile as Profile
import Feature.Search as Search
import Json.Decode as Decode
import Locale exposing (Locale(..))
import Localization exposing (LoadKind(..))
import Ports exposing (requestCsrf)
import Route
import Url exposing (Url)


type alias Flags =
    { languages : List String
    , savedLocale : Maybe String
    , csrf : String
    , verificationToken : String
    }


init : Decode.Value -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init rawFlags url key =
    let
        flags =
            Decode.decodeValue flagsDecoder rawFlags |> Result.withDefault defaultFlags

        requested =
            Locale.negotiate flags.savedLocale flags.languages

        ( loading, request ) =
            Localization.start Startup requested Localization.initial

        model =
            { key = key
            , url = url
            , route = Route.parse url
            , routeEpoch = 0
            , authGeneration = 0
            , auth = CheckingSession
            , csrf = flags.csrf
            , active = Nothing
            , requested = requested
            , bootFailed = False
            , loading = loading
            , drawerOpen = False
            , dialog = Nothing
            , flash = NoFlash
            , formatted = Nothing
            , account = Feature.Auth.State.initial flags.verificationToken
            , posts = Post.initial
            , feed = Feed.initial
            , communityPage = Community.initial
            , searchPage = Search.initial
            , notificationsPage = Notifications.initial
            , profile = Profile.initial
            , editorPage = Feature.Editor.State.initial
            , communityCreate = CommunityCreate.initial
            , management = Feature.CommunityManage.State.initial
            }
    in
    ( model, Cmd.batch [ loadCatalog request, loadSession model, requestCsrf ] )


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.map4 Flags
        (Decode.field "languages" (Decode.list Decode.string))
        (Decode.field "savedLocale" (Decode.nullable Decode.string))
        (Decode.field "csrf" Decode.string)
        (Decode.field "verificationToken" Decode.string)


defaultFlags : Flags
defaultFlags =
    { languages = [ "en-US" ], savedLocale = Nothing, csrf = "", verificationToken = "" }

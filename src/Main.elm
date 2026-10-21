port module Main exposing (main)

import Api
import Browser
import Browser.Navigation as Navigation
import Dict exposing (Dict)
import Domain
import File exposing (File)
import Generated.I18n as Translations
import Html exposing (Html, a, article, aside, bdi, button, div, form, h1, h2, h3, header, img, input, label, li, main_, nav, option, p, pre, section, select, small, span, strong, text, textarea, time, ul)
import Html.Attributes as A
import Html.Events as Events
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import List
import Locale exposing (Locale(..))
import Localization exposing (LoadKind(..))
import Remote exposing (Remote(..))
import Route
import Set exposing (Set)
import Ui.Rich
import Url exposing (Url)
import Url.Builder as Builder


port outgoing : Encode.Value -> Cmd msg


port incoming : (Decode.Value -> msg) -> Sub msg


type alias Flags =
    { languages : List String
    , savedLocale : Maybe String
    , csrf : String
    , verificationToken : String
    }


type AuthState
    = CheckingSession
    | Anonymous
    | Authenticated Domain.Identity


type alias Active =
    { locale : Locale
    , texts : Translations.I18n
    }


type Flash
    = NoFlash
    | FlashProblem Api.Problem
    | FlashSaved
    | FlashCreated
    | FlashDeleted
    | FlashLoggedOut
    | FlashVerificationSuccess
    | FlashRegistrationAccepted
    | FlashUploaded
    | FlashUploadFailed


type SearchResult
    = PostSearch (Domain.Page Domain.Post)
    | CommunitySearch (Domain.Page Domain.Community)


type EditorMode
    = CreateTopic String
    | CreateReply String
    | EditPost String


type alias EditorAttachment =
    { id : String, name : String, reference : String }


type alias EditorState =
    { mode : EditorMode
    , title : String
    , body : String
    , format : String
    , version : Maybe String
    , attachments : List EditorAttachment
    , uploading : Bool
    , saving : Bool
    , problem : Maybe Api.Problem
    , conflict : Maybe Domain.Source
    }


type AvatarChange
    = KeepAvatar
    | ClearAvatar
    | ReplaceAvatar String


type alias ProfileForm =
    { displayName : String
    , biography : String
    , avatar : AvatarChange
    , avatarUrl : String
    , uploading : Bool
    , saving : Bool
    , problem : Maybe Api.Problem
    }


type alias CommunityForm =
    { name : String
    , title : String
    , mode : String
    , readPolicy : String
    , postPolicy : String
    , busy : Bool
    , problem : Maybe Api.Problem
    }


type alias ManageState =
    { community : Remote Domain.Community
    , members : Remote (Domain.Page Domain.Roster)
    , managers : Remote (Domain.Page Domain.Roster)
    , memberOffset : Int
    , managerOffset : Int
    , actor : String
    , postId : String
    , contextId : String
    , readPolicy : String
    , postPolicy : String
    , problem : Maybe Api.Problem
    }


type ManagePostAction
    = RemoveCommunityPost
    | RestoreCommunityPost
    | HideSitePost
    | UnhideSitePost
    | ImportSitePost
    | AcceptSubmission
    | RejectSubmission
    | BackfillDiscussion


type LoadKind
    = LoadTopics
    | LoadCommunities
    | LoadCommunity String
    | LoadCommunityTopics String
    | LoadPost String
    | LoadReplies String
    | LoadNested String
    | LoadSearch String
    | LoadNotifications
    | LoadUnread
    | LoadPublicProfile String
    | LoadOwnProfile
    | LoadManageCommunity String
    | LoadMembers String Int
    | LoadManagers String Int
    | LoadSource String


type Action
    = LoginAction
    | LogoutAction
    | RegisterAction
    | ResendAction
    | VerifyAction
    | LikeAction String Bool
    | DeleteAction String
    | SaveEditorAction EditorMode
    | ReloadSourceAction
    | ProfileSaveAction
    | CommunityCreateAction
    | ManageAction String
    | ManagePostActionDone String ManagePostAction
    | ReadNoticeAction String
    | ReadAllAction
    | UploadEditorAction EditorMode
    | UploadAvatarAction


type alias SearchState =
    { kind : String
    , query : String
    , results : Remote SearchResult
    }


type alias Model =
    { key : Navigation.Key
    , url : Url
    , route : Route.Route
    , routeEpoch : Int
    , authGeneration : Int
    , auth : AuthState
    , csrf : String
    , verificationToken : String
    , active : Maybe Active
    , requested : Locale
    , bootFailed : Bool
    , loading : Localization.State
    , drawerOpen : Bool
    , dialog : Maybe String
    , flash : Flash
    , busy : Set String
    , topics : Remote (Domain.Page Domain.Post)
    , communities : Remote (Domain.Page Domain.Community)
    , community : Remote Domain.Community
    , communityTopics : Remote (Domain.Page Domain.Post)
    , post : Remote Domain.Post
    , replies : Remote (Domain.Page Domain.Post)
    , nestedReplies : Dict String (Remote (Domain.Page Domain.Post))
    , expandedReplies : Set String
    , search : SearchState
    , notifications : Remote Domain.NotificationPage
    , unreadCount : Maybe String
    , publicProfile : Remote Domain.Profile
    , ownProfile : Remote Domain.Profile
    , profileForm : ProfileForm
    , editor : Maybe EditorState
    , source : Remote Domain.Source
    , createCommunity : CommunityForm
    , manage : Maybe ManageState
    , loginIdentifier : String
    , loginPassword : String
    , loginProblem : Maybe Api.Problem
    , loginBusy : Bool
    , registerUsername : String
    , registerEmail : String
    , registerProblem : Maybe Api.Problem
    , registerBusy : Bool
    , verifyPassword : String
    , verifyProblem : Maybe Api.Problem
    , verifyBusy : Bool
    , verified : Bool
    , formatted : Maybe Formatting
    }


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
    | Loaded LoadKind Int Api.Response
    | ActionDone Action Int Api.Response
    | OpenDrawer
    | CloseDrawer
    | DrawerClosed
    | OpenDeleteDialog String
    | CloseDialog
    | ConfirmDelete String
    | Noop
    | LoginIdentifierChanged String
    | LoginPasswordChanged String
    | LoginSubmitted
    | Logout
    | RegisterUsernameChanged String
    | RegisterEmailChanged String
    | RegisterSubmitted
    | ResendSubmitted
    | VerifyPasswordChanged String
    | VerifySubmitted
    | SearchKindChanged String
    | SearchQueryChanged String
    | SearchSubmitted
    | ToggleReplies String
    | ToggleLike String Bool
    | MarkNoticeRead String
    | MarkAllNoticesRead
    | ProfileDisplayNameChanged String
    | ProfileBiographyChanged String
    | ProfileClearAvatar
    | ProfileSave
    | StartReply String
    | EditorTitleChanged String
    | EditorBodyChanged String
    | EditorFormatChanged String
    | EditorRemoveAttachment String
    | EditorFileSelected (Maybe File)
    | EditorSubmit
    | EditorUseLatest
    | EditorKeepDraft
    | CommunityNameChanged String
    | CommunityTitleChanged String
    | CommunityModeChanged String
    | CommunityReadChanged String
    | CommunityPostChanged String
    | CommunityCreate
    | ManageActorChanged String
    | ManagePostChanged String
    | ManageContextChanged String
    | ManageReadChanged String
    | ManagePostPolicyChanged String
    | ManageApplyPolicy
    | ManageAddMember
    | ManageRemoveMember String
    | ManageAddManager
    | ManageRemoveManager String
    | ManagePreviousMembers
    | ManageNextMembers
    | ManagePreviousManagers
    | ManageNextManagers
    | ManagePostAction String ManagePostAction
    | AvatarFileSelected (Maybe File)
    | DismissFlash


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
            , verificationToken = flags.verificationToken
            , active = Nothing
            , requested = requested
            , bootFailed = False
            , loading = loading
            , drawerOpen = False
            , dialog = Nothing
            , flash = NoFlash
            , busy = Set.empty
            , topics = NotAsked
            , communities = NotAsked
            , community = NotAsked
            , communityTopics = NotAsked
            , post = NotAsked
            , replies = NotAsked
            , nestedReplies = Dict.empty
            , expandedReplies = Set.empty
            , search = emptySearch
            , notifications = NotAsked
            , unreadCount = Nothing
            , publicProfile = NotAsked
            , ownProfile = NotAsked
            , profileForm = emptyProfileForm
            , editor = Nothing
            , source = NotAsked
            , createCommunity = emptyCommunityForm
            , manage = Nothing
            , loginIdentifier = ""
            , loginPassword = ""
            , loginProblem = Nothing
            , loginBusy = False
            , registerUsername = ""
            , registerEmail = ""
            , registerProblem = Nothing
            , registerBusy = False
            , verifyPassword = ""
            , verifyProblem = Nothing
            , verifyBusy = False
            , verified = False
            , formatted = Nothing
            }
    in
    ( model
    , Cmd.batch [ loadCatalog request, loadSession model, requestCsrf ]
    )


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
                        , drawerOpen = False
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
                                { model | auth = Authenticated identity }

                            Err problem ->
                                { model
                                    | auth = Anonymous
                                    , flash =
                                        if problem.status == 401 then
                                            model.flash

                                        else
                                            FlashProblem problem
                                }

                    ( loaded, command ) =
                        loadRoute changed
                in
                ( loaded, Cmd.batch [ command, unreadCommand loaded ] )

        Loaded kind epoch response ->
            receiveLoaded kind epoch response model

        ActionDone action epoch response ->
            receiveAction action epoch response model

        OpenDrawer ->
            ( { model | drawerOpen = True }, openDialog "navigation-drawer" )

        CloseDrawer ->
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
            ( { model | dialog = Nothing, flash = NoFlash }
            , Cmd.batch
                [ closeDialog "confirmation-dialog"
                , Api.send model.csrf "DELETE" ("/api/v1/posts/" ++ urlEncode id) "" (ActionDone (DeleteAction id) model.routeEpoch)
                ]
            )

        Noop ->
            ( model, Cmd.none )

        LoginIdentifierChanged value ->
            ( { model | loginIdentifier = value, loginProblem = Nothing }, Cmd.none )

        LoginPasswordChanged value ->
            ( { model | loginPassword = value, loginProblem = Nothing }, Cmd.none )

        LoginSubmitted ->
            if model.loginBusy then
                ( model, Cmd.none )

            else
                ( { model | loginBusy = True, loginProblem = Nothing }
                , Api.send model.csrf
                    "POST"
                    "/api/v1/auth/login"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "login", Encode.string model.loginIdentifier )
                            , ( "password", Encode.string model.loginPassword )
                            ]
                        )
                    )
                    (ActionDone LoginAction model.routeEpoch)
                )

        Logout ->
            ( model, Api.send model.csrf "POST" "/api/v1/auth/logout" "" (ActionDone LogoutAction model.routeEpoch) )

        RegisterUsernameChanged value ->
            ( { model | registerUsername = value, registerProblem = Nothing }, Cmd.none )

        RegisterEmailChanged value ->
            ( { model | registerEmail = value, registerProblem = Nothing }, Cmd.none )

        RegisterSubmitted ->
            if model.registerBusy then
                ( model, Cmd.none )

            else
                ( { model | registerBusy = True, registerProblem = Nothing }
                , Api.send ""
                    "POST"
                    "/api/v1/auth/register"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "username", Encode.string model.registerUsername )
                            , ( "email", Encode.string model.registerEmail )
                            ]
                        )
                    )
                    (ActionDone RegisterAction model.routeEpoch)
                )

        ResendSubmitted ->
            ( model
            , Api.send ""
                "POST"
                "/api/v1/auth/verification/resend"
                (Encode.encode 0 (Encode.object [ ( "email", Encode.string model.registerEmail ) ]))
                (ActionDone ResendAction model.routeEpoch)
            )

        VerifyPasswordChanged value ->
            ( { model | verifyPassword = value, verifyProblem = Nothing }, Cmd.none )

        VerifySubmitted ->
            if model.verifyBusy || String.isEmpty model.verificationToken then
                ( model, Cmd.none )

            else
                ( { model | verifyBusy = True, verifyProblem = Nothing }
                , Api.send ""
                    "POST"
                    "/api/v1/auth/verification/confirm"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "token", Encode.string model.verificationToken )
                            , ( "password", Encode.string model.verifyPassword )
                            ]
                        )
                    )
                    (ActionDone VerifyAction model.routeEpoch)
                )

        SearchKindChanged kind ->
            ( { model | search = (\search -> { search | kind = kind }) model.search }, Cmd.none )

        SearchQueryChanged query ->
            ( { model | search = (\search -> { search | query = query }) model.search }, Cmd.none )

        SearchSubmitted ->
            let
                query =
                    String.trim model.search.query

                target =
                    "/search"
                        ++ Builder.toQuery
                            [ Builder.string "kind" model.search.kind
                            , Builder.string "q" query
                            ]
            in
            if String.isEmpty query then
                ( { model | search = (\search -> { search | results = NotAsked }) model.search }, Cmd.none )

            else
                ( model, Navigation.pushUrl model.key target )

        ToggleReplies id ->
            if Set.member id model.expandedReplies then
                ( { model | expandedReplies = Set.remove id model.expandedReplies }, Cmd.none )

            else
                let
                    expanded =
                        { model | expandedReplies = Set.insert id model.expandedReplies }
                in
                if Dict.member id model.nestedReplies then
                    ( expanded, Cmd.none )

                else
                    ( { expanded | nestedReplies = Dict.insert id Loading expanded.nestedReplies }
                    , Api.get
                        ("/api/v1/posts/" ++ urlEncode id ++ "/replies?limit=20&offset=0")
                        (Loaded (LoadNested id) model.routeEpoch)
                    )

        ToggleLike id liked ->
            let
                key =
                    likeKey id
            in
            if Set.member key model.busy then
                ( model, Cmd.none )

            else
                ( { model | busy = Set.insert key model.busy }
                , Api.send model.csrf
                    (if liked then
                        "DELETE"

                     else
                        "POST"
                    )
                    ("/api/v1/posts/" ++ urlEncode id ++ "/likes")
                    ""
                    (ActionDone (LikeAction id liked) model.routeEpoch)
                )

        MarkNoticeRead id ->
            ( model, Api.send model.csrf "POST" ("/api/v1/notifications/" ++ urlEncode id ++ "/read") "" (ActionDone (ReadNoticeAction id) model.routeEpoch) )

        MarkAllNoticesRead ->
            case model.notifications of
                Ready page ->
                    ( model
                    , Api.send model.csrf
                        "POST"
                        "/api/v1/notifications/read-all"
                        (Encode.encode 0 (Encode.object [ ( "through_cursor", Encode.string page.cursor ) ]))
                        (ActionDone ReadAllAction model.routeEpoch)
                    )

                _ ->
                    ( model, Cmd.none )

        ProfileDisplayNameChanged value ->
            ( { model | profileForm = (\form -> { form | displayName = value, problem = Nothing }) model.profileForm }, Cmd.none )

        ProfileBiographyChanged value ->
            ( { model | profileForm = (\form -> { form | biography = value, problem = Nothing }) model.profileForm }, Cmd.none )

        ProfileClearAvatar ->
            ( { model | profileForm = (\form -> { form | avatar = ClearAvatar, avatarUrl = "", problem = Nothing }) model.profileForm }, Cmd.none )

        ProfileSave ->
            let
                avatar =
                    case model.profileForm.avatar of
                        KeepAvatar ->
                            []

                        ClearAvatar ->
                            [ ( "avatar_upload_id", Encode.null ) ]

                        ReplaceAvatar id ->
                            [ ( "avatar_upload_id", Encode.string id ) ]
            in
            ( { model | profileForm = (\form -> { form | saving = True, problem = Nothing }) model.profileForm }
            , Api.send model.csrf
                "PATCH"
                "/api/v1/profile"
                (Encode.encode 0
                    (Encode.object
                        ([ ( "display_name", Encode.string model.profileForm.displayName )
                         , ( "biography", Encode.string model.profileForm.biography )
                         ]
                            ++ avatar
                        )
                    )
                )
                (ActionDone ProfileSaveAction model.routeEpoch)
            )

        StartReply postId ->
            ( { model | editor = Just (emptyEditor (CreateReply postId)) }, focus "editor-body" )

        EditorTitleChanged value ->
            setEditor model (\editor -> { editor | title = value, problem = Nothing }) Cmd.none

        EditorBodyChanged value ->
            setEditor model (\editor -> { editor | body = value, problem = Nothing }) Cmd.none

        EditorFormatChanged value ->
            setEditor model (\editor -> { editor | format = value, problem = Nothing }) Cmd.none

        EditorRemoveAttachment id ->
            setEditor model
                (\editor -> { editor | attachments = List.filter (\item -> item.id /= id) editor.attachments, problem = Nothing })
                Cmd.none

        EditorFileSelected maybeFile ->
            case ( maybeFile, model.editor ) of
                ( Just file, Just editor ) ->
                    ( { model | editor = Just { editor | uploading = True, problem = Nothing } }
                    , Api.upload model.csrf "post" file (ActionDone (UploadEditorAction editor.mode) model.routeEpoch)
                    )

                _ ->
                    ( model, Cmd.none )

        EditorSubmit ->
            case model.editor of
                Just editor ->
                    if editor.saving then
                        ( model, Cmd.none )

                    else
                        submitEditor model editor

                Nothing ->
                    ( model, Cmd.none )

        EditorUseLatest ->
            case ( model.editor, model.editor |> Maybe.andThen .conflict ) of
                ( Just editor, Just source ) ->
                    ( { model
                        | editor =
                            Just
                                { editor
                                    | title = source.title
                                    , body = source.body
                                    , format = source.format
                                    , version = Just source.version
                                    , attachments = sourceAttachments source
                                    , conflict = Nothing
                                    , problem = Nothing
                                }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        EditorKeepDraft ->
            setEditor model (\editor -> { editor | conflict = Nothing }) Cmd.none

        CommunityNameChanged value ->
            ( { model | createCommunity = (\form -> { form | name = value, problem = Nothing }) model.createCommunity }, Cmd.none )

        CommunityTitleChanged value ->
            ( { model | createCommunity = (\form -> { form | title = value, problem = Nothing }) model.createCommunity }, Cmd.none )

        CommunityModeChanged value ->
            ( { model | createCommunity = (\form -> { form | mode = value, problem = Nothing }) model.createCommunity }, Cmd.none )

        CommunityReadChanged value ->
            ( { model
                | createCommunity =
                    (\form ->
                        { form
                            | readPolicy = value
                            , postPolicy =
                                if value == "members" && form.postPolicy == "eligible_users" then
                                    "members"

                                else
                                    form.postPolicy
                        }
                    )
                        model.createCommunity
              }
            , Cmd.none
            )

        CommunityPostChanged value ->
            ( { model
                | createCommunity =
                    (\form ->
                        { form
                            | postPolicy = value
                            , readPolicy =
                                if value == "eligible_users" && form.readPolicy == "members" then
                                    "eligible_users"

                                else
                                    form.readPolicy
                        }
                    )
                        model.createCommunity
              }
            , Cmd.none
            )

        CommunityCreate ->
            if model.createCommunity.busy then
                ( model, Cmd.none )

            else
                ( { model | createCommunity = (\form -> { form | busy = True, problem = Nothing }) model.createCommunity }
                , Api.send model.csrf
                    "POST"
                    "/api/v1/communities"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "name", Encode.string model.createCommunity.name )
                            , ( "title", Encode.string model.createCommunity.title )
                            , ( "mode", Encode.string model.createCommunity.mode )
                            , ( "read_policy", Encode.string model.createCommunity.readPolicy )
                            , ( "post_policy", Encode.string model.createCommunity.postPolicy )
                            ]
                        )
                    )
                    (ActionDone CommunityCreateAction model.routeEpoch)
                )

        ManageActorChanged value ->
            setManage model (\manage -> { manage | actor = value, problem = Nothing }) Cmd.none

        ManagePostChanged value ->
            setManage model (\manage -> { manage | postId = value, problem = Nothing }) Cmd.none

        ManageContextChanged value ->
            setManage model (\manage -> { manage | contextId = value, problem = Nothing }) Cmd.none

        ManageReadChanged value ->
            setManage model
                (\manage ->
                    { manage
                        | readPolicy = value
                        , postPolicy =
                            if value == "members" && manage.postPolicy == "eligible_users" then
                                "members"

                            else
                                manage.postPolicy
                    }
                )
                Cmd.none

        ManagePostPolicyChanged value ->
            setManage model
                (\manage ->
                    { manage
                        | postPolicy = value
                        , readPolicy =
                            if value == "eligible_users" && manage.readPolicy == "members" then
                                "eligible_users"

                            else
                                manage.readPolicy
                    }
                )
                Cmd.none

        ManageApplyPolicy ->
            case model.manage of
                Just manage ->
                    manageRequest model
                        "policy"
                        "PUT"
                        ("/api/v1/communities/" ++ urlEncode (communityId model.route) ++ "/policy")
                        (Encode.encode 0
                            (Encode.object
                                [ ( "read_policy", Encode.string manage.readPolicy )
                                , ( "post_policy", Encode.string manage.postPolicy )
                                ]
                            )
                        )

                Nothing ->
                    ( model, Cmd.none )

        ManageAddMember ->
            manageActorRequest model "add-member" "POST" "members"

        ManageRemoveMember actor ->
            manageActorRequestFor model "remove-member" "DELETE" "members" actor

        ManageAddManager ->
            manageActorRequest model "add-manager" "POST" "managers"

        ManageRemoveManager actor ->
            manageActorRequestFor model "remove-manager" "DELETE" "managers" actor

        ManagePreviousMembers ->
            managePage model True -20

        ManageNextMembers ->
            managePage model True 20

        ManagePreviousManagers ->
            managePage model False -20

        ManageNextManagers ->
            managePage model False 20

        ManagePostAction id action ->
            managePostRequest model id action

        AvatarFileSelected maybeFile ->
            case maybeFile of
                Just file ->
                    ( { model | profileForm = (\form -> { form | uploading = True, problem = Nothing }) model.profileForm }
                    , Api.upload model.csrf "avatar" file (ActionDone UploadAvatarAction model.routeEpoch)
                    )

                Nothing ->
                    ( model, Cmd.none )

        DismissFlash ->
            ( { model | flash = NoFlash }, Cmd.none )


loadSession : Model -> Cmd Msg
loadSession model =
    Api.get "/api/v1/auth/session"
        (SessionLoaded model.authGeneration << Api.decodeResponse Domain.identity)


unreadCommand : Model -> Cmd Msg
unreadCommand model =
    case model.auth of
        Authenticated _ ->
            Api.get "/api/v1/notifications/unread-count" (Loaded LoadUnread model.routeEpoch)

        _ ->
            Cmd.none


selectLocale : String -> Model -> ( Model, Cmd Msg )
selectLocale raw model =
    case Locale.fromString raw of
        Nothing ->
            ( model, Cmd.none )

        Just target ->
            case model.active of
                Just active ->
                    if active.locale == target then
                        ( model, focus "language-select" )

                    else
                        beginSwitch target model

                Nothing ->
                    beginStartup target model


beginStartup : Locale -> Model -> ( Model, Cmd Msg )
beginStartup target model =
    let
        ( loading, request ) =
            Localization.start Startup target model.loading
    in
    ( { model | requested = target, loading = loading, bootFailed = False }
    , loadCatalog request
    )


beginSwitch : Locale -> Model -> ( Model, Cmd Msg )
beginSwitch target model =
    let
        ( loading, request ) =
            Localization.start Switch target model.loading
    in
    ( { model | requested = target, loading = loading }
    , loadCatalog request
    )


resolveCatalog :
    Localization.Pending
    -> Result Http.Error (Translations.I18n -> Translations.I18n)
    -> Model
    -> ( Model, Cmd Msg )
resolveCatalog request result model =
    case result |> Result.map (\apply -> apply (catalog request.target)) of
        Err _ ->
            rejectCatalog request model

        Ok texts ->
            if
                Translations.arrivedLanguage texts
                    == Locale.toLanguage request.target
                    && Translations.catalogId texts
                    == Locale.code request.target
            then
                acceptCatalog request texts model

            else
                rejectCatalog request model


acceptCatalog : Localization.Pending -> Translations.I18n -> Model -> ( Model, Cmd Msg )
acceptCatalog request texts model =
    case Localization.accept request model.loading of
        Err _ ->
            ( model, Cmd.none )

        Ok loading ->
            let
                active =
                    { locale = request.target, texts = texts }

                focusTarget =
                    case request.kind of
                        Switch ->
                            "language-select"

                        _ ->
                            "main-heading"
            in
            ( { model
                | active = Just active
                , requested = request.target
                , loading = loading
                , bootFailed = False
              }
            , Cmd.batch
                [ setLocale active.locale
                , requestFormatting active.locale
                , focus focusTarget
                ]
            )


rejectCatalog : Localization.Pending -> Model -> ( Model, Cmd Msg )
rejectCatalog request model =
    case Localization.fail request model.loading of
        Err _ ->
            ( model, Cmd.none )

        Ok failed ->
            case request.kind of
                Startup ->
                    startFallback request failed model

                Fallback _ ->
                    ( { model | loading = failed, bootFailed = True }, Cmd.none )

                Switch ->
                    ( { model | loading = failed }, focus "language-select" )


startFallback : Localization.Pending -> Localization.State -> Model -> ( Model, Cmd Msg )
startFallback failedRequest failed model =
    if failedRequest.target == English then
        ( { model | loading = failed, bootFailed = True }, Cmd.none )

    else
        let
            ( loading, request ) =
                Localization.start (Fallback failedRequest.target) English failed
        in
        ( { model | loading = loading, requested = failedRequest.target, bootFailed = False }
        , loadCatalog request
        )


loadCatalog : Localization.Pending -> Cmd Msg
loadCatalog request =
    Translations.loadMessages (CatalogResult request) (catalog request.target)


catalog : Locale -> Translations.I18n
catalog locale =
    Translations.init { lang = Locale.toLanguage locale, path = "/assets/i18n" }


loadRoute : Model -> ( Model, Cmd Msg )
loadRoute model =
    let
        epoch =
            model.routeEpoch

        reset =
            { model
                | topics = NotAsked
                , communities = NotAsked
                , community = NotAsked
                , communityTopics = NotAsked
                , post = NotAsked
                , replies = NotAsked
                , nestedReplies = Dict.empty
                , expandedReplies = Set.empty
                , publicProfile = NotAsked
                , ownProfile = NotAsked
                , notifications = NotAsked
                , unreadCount = Nothing
                , source = NotAsked
                , editor = Nothing
                , manage = Nothing
            }
    in
    case model.route of
        Route.Latest ->
            ( { reset | topics = Loading }
            , Api.get ("/api/v1/topics?limit=20&offset=" ++ String.fromInt (Route.offset model.url)) (Loaded LoadTopics epoch)
            )

        Route.Communities ->
            ( { reset | communities = Loading }
            , Api.get ("/api/v1/communities?limit=20&offset=" ++ String.fromInt (Route.offset model.url)) (Loaded LoadCommunities epoch)
            )

        Route.Community id ->
            ( { reset | community = Loading, communityTopics = Loading }
            , Cmd.batch
                [ Api.get ("/api/v1/communities/" ++ urlEncode id) (Loaded (LoadCommunity id) epoch)
                , Api.get ("/api/v1/communities/" ++ urlEncode id ++ "/topics?limit=20&offset=" ++ String.fromInt (Route.offset model.url)) (Loaded (LoadCommunityTopics id) epoch)
                ]
            )

        Route.Post id ->
            ( { reset | post = Loading, replies = Loading }
            , Cmd.batch
                [ Api.get ("/api/v1/posts/" ++ urlEncode id) (Loaded (LoadPost id) epoch)
                , Api.get ("/api/v1/posts/" ++ urlEncode id ++ "/replies?limit=20&offset=" ++ String.fromInt (Route.offset model.url)) (Loaded (LoadReplies id) epoch)
                ]
            )

        Route.NewCommunity ->
            ( { reset | createCommunity = emptyCommunityForm }
            , Cmd.none
            )

        Route.NewTopic id ->
            ( { reset | community = Loading, editor = Just (emptyEditor (CreateTopic id)) }
            , Api.get ("/api/v1/communities/" ++ urlEncode id) (Loaded (LoadCommunity id) epoch)
            )

        Route.EditPost id ->
            ( { reset | source = Loading }
            , Api.get ("/api/v1/posts/" ++ urlEncode id ++ "/source") (Loaded (LoadSource id) epoch)
            )

        Route.Login ->
            ( reset, Cmd.none )

        Route.Register ->
            ( reset, Cmd.none )

        Route.Verify ->
            ( reset, Cmd.none )

        Route.Search ->
            let
                kind =
                    case Route.query "kind" model.url of
                        "communities" ->
                            "communities"

                        _ ->
                            "posts"

                query =
                    Route.query "q" model.url

                search =
                    { kind = kind
                    , query = query
                    , results =
                        if String.isEmpty (String.trim query) then
                            NotAsked

                        else
                            Loading
                    }
            in
            ( { reset | search = search }
            , if String.isEmpty (String.trim query) then
                Cmd.none

              else
                Api.get
                    ("/api/v1/search"
                        ++ Builder.toQuery
                            [ Builder.string "kind" kind
                            , Builder.string "q" query
                            , Builder.int "offset" (Route.offset model.url)
                            ]
                    )
                    (Loaded (LoadSearch kind) epoch)
            )

        Route.Notifications ->
            case model.auth of
                Authenticated _ ->
                    ( { reset | notifications = Loading }, loadNotifications reset )

                _ ->
                    ( reset, Cmd.none )

        Route.Profile username ->
            ( { reset | publicProfile = Loading }
            , Api.get ("/api/v1/profiles/" ++ urlEncode username) (Loaded (LoadPublicProfile username) epoch)
            )

        Route.Settings ->
            case model.auth of
                Authenticated _ ->
                    ( { reset | ownProfile = Loading }
                    , Api.get "/api/v1/profile" (Loaded LoadOwnProfile epoch)
                    )

                _ ->
                    ( reset, Cmd.none )

        Route.Manage id ->
            case model.auth of
                Authenticated _ ->
                    let
                        initial =
                            { community = Loading
                            , members = Loading
                            , managers = Loading
                            , memberOffset = 0
                            , managerOffset = 0
                            , actor = ""
                            , postId = ""
                            , contextId = ""
                            , readPolicy = "eligible_users"
                            , postPolicy = "eligible_users"
                            , problem = Nothing
                            }

                        ( changed, command ) =
                            loadManageState epoch id initial { reset | manage = Just initial }
                    in
                    ( changed, command )

                _ ->
                    ( reset, Cmd.none )

        Route.NotFound ->
            ( reset, Cmd.none )


loadManageState : Int -> String -> ManageState -> Model -> ( Model, Cmd Msg )
loadManageState epoch id manage model =
    ( { model | manage = Just manage }
    , Cmd.batch
        [ Api.get ("/api/v1/communities/" ++ urlEncode id) (Loaded (LoadManageCommunity id) epoch)
        , Api.get ("/api/v1/communities/" ++ urlEncode id ++ "/members?limit=20&offset=" ++ String.fromInt manage.memberOffset) (Loaded (LoadMembers id manage.memberOffset) epoch)
        , Api.get ("/api/v1/communities/" ++ urlEncode id ++ "/managers?limit=20&offset=" ++ String.fromInt manage.managerOffset) (Loaded (LoadManagers id manage.managerOffset) epoch)
        ]
    )


loadNotifications : Model -> Cmd Msg
loadNotifications model =
    Cmd.batch
        [ Api.get ("/api/v1/notifications?limit=20&offset=" ++ String.fromInt (Route.offset model.url)) (Loaded LoadNotifications model.routeEpoch)
        , Api.get "/api/v1/notifications/unread-count" (Loaded LoadUnread model.routeEpoch)
        ]


receiveLoaded : LoadKind -> Int -> Api.Response -> Model -> ( Model, Cmd Msg )
receiveLoaded kind epoch response model =
    if epoch /= model.routeEpoch then
        ( model, Cmd.none )

    else
        let
            withProblem remoteName problem =
                let
                    base =
                        authProblem model problem
                in
                case remoteName of
                    "topics" ->
                        { base | topics = Failed problem }

                    "communities" ->
                        { base | communities = Failed problem }

                    "community" ->
                        { base | community = Failed problem }

                    "communityTopics" ->
                        { base | communityTopics = Failed problem }

                    "post" ->
                        { base | post = Failed problem }

                    "replies" ->
                        { base | replies = Failed problem }

                    "search" ->
                        { base | search = (\search -> { search | results = Failed problem }) base.search }

                    "publicProfile" ->
                        { base | publicProfile = Failed problem }

                    "ownProfile" ->
                        { base | ownProfile = Failed problem }

                    "source" ->
                        { base | source = Failed problem }

                    "notifications" ->
                        { base | notifications = Failed problem }

                    _ ->
                        base
        in
        case ( kind, Api.decodeResponse (Decode.succeed ()) response ) of
            ( LoadTopics, Ok _ ) ->
                case Api.decodeResponse (Domain.page Domain.post) response of
                    Ok page ->
                        ( { model | topics = Ready page }, Cmd.none )

                    Err problem ->
                        ( withProblem "topics" problem, Cmd.none )

            ( LoadCommunities, Ok _ ) ->
                case Api.decodeResponse (Domain.page Domain.community) response of
                    Ok page ->
                        ( { model | communities = Ready page }, Cmd.none )

                    Err problem ->
                        ( withProblem "communities" problem, Cmd.none )

            ( LoadCommunity id, Ok _ ) ->
                case Api.decodeResponse Domain.community response of
                    Ok community ->
                        ( { model | community = Ready community }, Cmd.none )

                    Err problem ->
                        ( withProblem "community" problem, Cmd.none )

            ( LoadCommunityTopics id, Ok _ ) ->
                case Api.decodeResponse (Domain.page Domain.post) response of
                    Ok page ->
                        ( { model | communityTopics = Ready page }, Cmd.none )

                    Err problem ->
                        ( withProblem "communityTopics" problem, Cmd.none )

            ( LoadPost id, Ok _ ) ->
                case Api.decodeResponse Domain.post response of
                    Ok post ->
                        ( { model | post = Ready post }, Cmd.none )

                    Err problem ->
                        ( withProblem "post" problem, Cmd.none )

            ( LoadReplies id, Ok _ ) ->
                case Api.decodeResponse (Domain.page Domain.post) response of
                    Ok page ->
                        ( { model | replies = Ready page }, Cmd.none )

                    Err problem ->
                        ( withProblem "replies" problem, Cmd.none )

            ( LoadNested parent, Ok _ ) ->
                case Api.decodeResponse (Domain.page Domain.post) response of
                    Ok page ->
                        ( { model | nestedReplies = Dict.insert parent (Ready page) model.nestedReplies }, Cmd.none )

                    Err problem ->
                        ( authProblem model problem
                        , Cmd.none
                        )

            ( LoadSearch searchKind, Ok _ ) ->
                let
                    decoder =
                        if searchKind == "communities" then
                            Decode.map CommunitySearch (Domain.page Domain.community)

                        else
                            Decode.map PostSearch (Domain.page Domain.post)
                in
                case Api.decodeResponse decoder response of
                    Ok result ->
                        ( { model | search = (\search -> { search | results = Ready result }) model.search }, Cmd.none )

                    Err problem ->
                        ( withProblem "search" problem, Cmd.none )

            ( LoadNotifications, Ok _ ) ->
                case Api.decodeResponse Domain.notificationPage response of
                    Ok page ->
                        ( { model | notifications = Ready page }, Cmd.none )

                    Err problem ->
                        ( withProblem "notifications" problem, Cmd.none )

            ( LoadUnread, Ok _ ) ->
                case Api.decodeResponse (Decode.field "count" Decode.int) response of
                    Ok count ->
                        ( { model | unreadCount = Just (String.fromInt count) }, Cmd.none )

                    Err _ ->
                        ( model, Cmd.none )

            ( LoadPublicProfile username, Ok _ ) ->
                case Api.decodeResponse Domain.profile response of
                    Ok profile ->
                        ( { model | publicProfile = Ready profile }, Cmd.none )

                    Err problem ->
                        ( withProblem "publicProfile" problem, Cmd.none )

            ( LoadOwnProfile, Ok _ ) ->
                case Api.decodeResponse Domain.profile response of
                    Ok profile ->
                        ( { model
                            | ownProfile = Ready profile
                            , profileForm = profileFormFrom profile
                          }
                        , Cmd.none
                        )

                    Err problem ->
                        ( withProblem "ownProfile" problem, Cmd.none )

            ( LoadManageCommunity id, Ok _ ) ->
                case Api.decodeResponse Domain.community response of
                    Ok community ->
                        ( updateManageRecord model
                            (\manage ->
                                { manage
                                    | community = Ready community
                                    , readPolicy = community.readPolicy
                                    , postPolicy = community.postPolicy
                                }
                            )
                        , Cmd.none
                        )

                    Err problem ->
                        ( updateManageRecord model (\manage -> { manage | community = Failed problem, problem = Just problem })
                        , Cmd.none
                        )

            ( LoadMembers id offset, Ok _ ) ->
                case Api.decodeResponse (Domain.page Domain.roster) response of
                    Ok page ->
                        ( updateManageRecord model (\manage -> { manage | members = Ready page })
                        , Cmd.none
                        )

                    Err problem ->
                        ( updateManageRecord model (\manage -> { manage | members = Failed problem, problem = Just problem })
                        , Cmd.none
                        )

            ( LoadManagers id offset, Ok _ ) ->
                case Api.decodeResponse (Domain.page Domain.roster) response of
                    Ok page ->
                        ( updateManageRecord model (\manage -> { manage | managers = Ready page })
                        , Cmd.none
                        )

                    Err problem ->
                        ( updateManageRecord model (\manage -> { manage | managers = Failed problem, problem = Just problem })
                        , Cmd.none
                        )

            ( LoadSource id, Ok _ ) ->
                case Api.decodeResponse Domain.source response of
                    Ok source ->
                        ( { model
                            | source = Ready source
                            , editor =
                                Just
                                    { mode = EditPost id
                                    , title = source.title
                                    , body = source.body
                                    , format =
                                        if String.isEmpty source.format then
                                            "legacy"

                                        else
                                            source.format
                                    , version = Just source.version
                                    , attachments = sourceAttachments source
                                    , uploading = False
                                    , saving = False
                                    , problem = Nothing
                                    , conflict = Nothing
                                    }
                          }
                        , Cmd.none
                        )

                    Err problem ->
                        ( withProblem "source" problem, Cmd.none )

            ( _, Err problem ) ->
                case kind of
                    LoadTopics ->
                        ( withProblem "topics" problem, Cmd.none )

                    LoadCommunities ->
                        ( withProblem "communities" problem, Cmd.none )

                    LoadCommunity _ ->
                        ( withProblem "community" problem, Cmd.none )

                    LoadCommunityTopics _ ->
                        ( withProblem "communityTopics" problem, Cmd.none )

                    LoadPost _ ->
                        ( withProblem "post" problem, Cmd.none )

                    LoadReplies _ ->
                        ( withProblem "replies" problem, Cmd.none )

                    LoadNested parent ->
                        let
                            base =
                                authProblem model problem
                        in
                        ( { base | nestedReplies = Dict.insert parent (Failed problem) base.nestedReplies }, Cmd.none )

                    LoadSearch _ ->
                        ( withProblem "search" problem, Cmd.none )

                    LoadNotifications ->
                        ( withProblem "notifications" problem, Cmd.none )

                    LoadUnread ->
                        ( model, Cmd.none )

                    LoadPublicProfile _ ->
                        ( withProblem "publicProfile" problem, Cmd.none )

                    LoadOwnProfile ->
                        ( withProblem "ownProfile" problem, Cmd.none )

                    LoadManageCommunity _ ->
                        ( updateManageRecord model (\manage -> { manage | community = Failed problem, problem = Just problem }), Cmd.none )

                    LoadMembers _ _ ->
                        ( updateManageRecord model (\manage -> { manage | members = Failed problem, problem = Just problem }), Cmd.none )

                    LoadManagers _ _ ->
                        ( updateManageRecord model (\manage -> { manage | managers = Failed problem, problem = Just problem }), Cmd.none )

                    LoadSource _ ->
                        ( withProblem "source" problem, Cmd.none )


receiveAction : Action -> Int -> Api.Response -> Model -> ( Model, Cmd Msg )
receiveAction action epoch response model =
    if epoch /= model.routeEpoch && action /= LogoutAction && action /= LoginAction then
        ( model, Cmd.none )

    else
        case action of
            LoginAction ->
                case Api.decodeResponse Domain.identity response of
                    Ok identity ->
                        let
                            changed =
                                { model
                                    | auth = Authenticated identity
                                    , authGeneration = model.authGeneration + 1
                                    , loginBusy = False
                                    , loginPassword = ""
                                    , loginProblem = Nothing
                                    , flash = NoFlash
                                }
                        in
                        ( { changed | routeEpoch = changed.routeEpoch + 1 }
                        , Cmd.batch [ Navigation.pushUrl changed.key "/", requestCsrf ]
                        )

                    Err problem ->
                        ( { model | loginBusy = False, loginProblem = Just problem }, Cmd.none )

            LogoutAction ->
                case Api.decodeUnit response of
                    Ok () ->
                        ( clearPrivate
                            { model
                                | auth = Anonymous
                                , authGeneration = model.authGeneration + 1
                                , csrf = ""
                                , flash = FlashLoggedOut
                                , routeEpoch = model.routeEpoch + 1
                            }
                        , Cmd.batch [ Navigation.pushUrl model.key "/login", requestCsrf ]
                        )

                    Err problem ->
                        ( { model | flash = FlashProblem problem }, Cmd.none )

            RegisterAction ->
                case Api.decodeUnit response of
                    Ok () ->
                        ( { model | registerBusy = False, flash = FlashRegistrationAccepted }, Cmd.none )

                    Err problem ->
                        ( { model | registerBusy = False, registerProblem = Just problem }, Cmd.none )

            ResendAction ->
                case Api.decodeUnit response of
                    Ok () ->
                        ( { model | flash = FlashRegistrationAccepted }, Cmd.none )

                    Err problem ->
                        ( { model | registerProblem = Just problem }, Cmd.none )

            VerifyAction ->
                case Api.decodeUnit response of
                    Ok () ->
                        ( { model | verifyBusy = False, verifyPassword = "", verificationToken = "", verified = True, flash = FlashVerificationSuccess }, Cmd.none )

                    Err problem ->
                        ( { model | verifyBusy = False, verifyProblem = Just problem }, Cmd.none )

            LikeAction id liked ->
                case Api.decodeUnit response of
                    Ok () ->
                        ( applyLike id liked { model | busy = Set.remove (likeKey id) model.busy }, Cmd.none )

                    Err problem ->
                        let
                            authorized =
                                authProblem model problem

                            base =
                                { authorized | busy = Set.remove (likeKey id) authorized.busy }
                        in
                        ( { base | flash = FlashProblem problem }, Cmd.none )

            DeleteAction id ->
                case Api.decodeUnit response of
                    Ok () ->
                        ( { model | flash = FlashDeleted }, Navigation.pushUrl model.key "/" )

                    Err problem ->
                        ( problemState model problem, Cmd.none )

            SaveEditorAction mode ->
                case Api.decodeResponse Domain.post response of
                    Ok post ->
                        ( { model | editor = Nothing }
                        , Navigation.pushUrl model.key
                            (Route.path
                                (case mode of
                                    CreateReply parent ->
                                        Route.Post parent

                                    _ ->
                                        Route.Post post.id
                                )
                            )
                        )

                    Err problem ->
                        case model.editor of
                            Just editor ->
                                if problem.status == 409 && String.contains "edit_conflict" problem.detail then
                                    ( { model | editor = Just { editor | saving = False, problem = Just problem }, source = Loading }
                                    , case mode of
                                        EditPost postId ->
                                            Api.get ("/api/v1/posts/" ++ urlEncode postId ++ "/source") (ActionDone ReloadSourceAction model.routeEpoch)

                                        _ ->
                                            Cmd.none
                                    )

                                else
                                    let
                                        base =
                                            authProblem model problem
                                    in
                                    ( { base | editor = Just { editor | saving = False, problem = Just problem } }, Cmd.none )

                            Nothing ->
                                ( model, Cmd.none )

            ReloadSourceAction ->
                case Api.decodeResponse Domain.source response of
                    Ok source ->
                        case model.editor of
                            Just editor ->
                                ( { model | editor = Just { editor | conflict = Just source }, source = Ready source }, Cmd.none )

                            Nothing ->
                                ( model, Cmd.none )

                    Err problem ->
                        ( { model | flash = FlashProblem problem }, Cmd.none )

            ProfileSaveAction ->
                case Api.decodeResponse Domain.profile response of
                    Ok profile ->
                        ( { model
                            | ownProfile = Ready profile
                            , profileForm = profileFormFrom profile
                            , flash = FlashSaved
                          }
                        , Cmd.none
                        )

                    Err problem ->
                        ( { model | profileForm = (\form -> { form | saving = False, problem = Just problem }) model.profileForm }, Cmd.none )

            CommunityCreateAction ->
                case Api.decodeResponse Domain.community response of
                    Ok community ->
                        ( { model | createCommunity = emptyCommunityForm, flash = FlashCreated }
                        , Navigation.pushUrl model.key (Route.path (Route.Community community.id))
                        )

                    Err problem ->
                        ( { model | createCommunity = (\form -> { form | busy = False, problem = Just problem }) model.createCommunity }, Cmd.none )

            ManageAction key ->
                case Api.decodeUnit response of
                    Ok () ->
                        let
                            changed =
                                { model | flash = FlashSaved }
                        in
                        case model.route of
                            Route.Manage id ->
                                loadManageState model.routeEpoch
                                    id
                                    (Maybe.withDefault emptyManage (model.manage |> Maybe.map (\manage -> { manage | problem = Nothing })))
                                    changed

                            _ ->
                                ( changed, Cmd.none )

                    Err problem ->
                        let
                            base =
                                authProblem model problem
                        in
                        ( { base
                            | flash = FlashProblem problem
                            , manage = model.manage |> Maybe.map (\manage -> { manage | problem = Just problem })
                          }
                        , Cmd.none
                        )

            ManagePostActionDone key managedAction ->
                case Api.decodeUnit response of
                    Ok () ->
                        let
                            changed =
                                { model | flash = FlashSaved }
                        in
                        case model.route of
                            Route.Manage id ->
                                loadManageState model.routeEpoch
                                    id
                                    (Maybe.withDefault emptyManage (model.manage |> Maybe.map (\manage -> { manage | problem = Nothing })))
                                    changed

                            _ ->
                                ( changed, Cmd.none )

                    Err problem ->
                        let
                            base =
                                authProblem model problem
                        in
                        ( { base
                            | flash = FlashProblem problem
                            , manage = model.manage |> Maybe.map (\manage -> { manage | problem = Just problem })
                          }
                        , Cmd.none
                        )

            ReadNoticeAction id ->
                case Api.decodeUnit response of
                    Ok () ->
                        ( model, loadNotifications model )

                    Err problem ->
                        ( problemState model problem, Cmd.none )

            ReadAllAction ->
                case Api.decodeUnit response of
                    Ok () ->
                        ( model, loadNotifications model )

                    Err problem ->
                        ( problemState model problem, Cmd.none )

            UploadEditorAction mode ->
                case Api.decodeResponse Domain.media response of
                    Ok uploaded ->
                        case model.editor of
                            Just editor ->
                                if editor.mode /= mode then
                                    ( model, Cmd.none )

                                else
                                    let
                                        label =
                                            if String.isEmpty uploaded.name then
                                                uploaded.id

                                            else
                                                uploaded.name

                                        markdown =
                                            if String.startsWith "image/" uploaded.mediaType then
                                                "![" ++ label ++ "](" ++ uploaded.reference ++ ")"

                                            else
                                                "[" ++ label ++ "](" ++ uploaded.reference ++ ")"

                                        separator =
                                            if String.isEmpty (String.trim editor.body) then
                                                ""

                                            else
                                                "\n\n"
                                    in
                                    ( { model
                                        | editor =
                                            Just
                                                { editor
                                                    | uploading = False
                                                    , body = String.trimRight editor.body ++ separator ++ markdown ++ "\n"
                                                    , attachments = editor.attachments ++ [ { id = uploaded.id, name = uploaded.name, reference = uploaded.reference } ]
                                                }
                                        , flash = FlashUploaded
                                      }
                                    , focus "editor-body"
                                    )

                            Nothing ->
                                ( model, Cmd.none )

                    Err problem ->
                        ( { model
                            | flash = FlashUploadFailed
                            , editor = model.editor |> Maybe.map (\editor -> { editor | uploading = False, problem = Just problem })
                          }
                        , Cmd.none
                        )

            UploadAvatarAction ->
                case Api.decodeResponse Domain.media response of
                    Ok uploaded ->
                        ( { model
                            | profileForm =
                                (\form ->
                                    { form
                                        | uploading = False
                                        , avatar = ReplaceAvatar uploaded.id
                                        , avatarUrl = uploaded.preview
                                    }
                                )
                                    model.profileForm
                            , flash = FlashUploaded
                          }
                        , Cmd.none
                        )

                    Err problem ->
                        ( { model | profileForm = (\form -> { form | uploading = False, problem = Just problem }) model.profileForm }, Cmd.none )


submitEditor : Model -> EditorState -> ( Model, Cmd Msg )
submitEditor model editor =
    let
        attachmentIds =
            Encode.list Encode.string (List.map .id editor.attachments)

        ( method, url, encodedBody ) =
            case editor.mode of
                CreateTopic targetCommunity ->
                    ( "POST"
                    , "/api/v1/communities/" ++ urlEncode targetCommunity ++ "/topics"
                    , Encode.encode 0
                        (Encode.object
                            [ ( "title", Encode.string editor.title )
                            , ( "body", Encode.string editor.body )
                            , ( "content_format", Encode.string editor.format )
                            , ( "attachment_ids", attachmentIds )
                            ]
                        )
                    )

                CreateReply postId ->
                    ( "POST"
                    , "/api/v1/posts/" ++ urlEncode postId ++ "/replies"
                    , Encode.encode 0
                        (Encode.object
                            [ ( "body", Encode.string editor.body )
                            , ( "content_format", Encode.string editor.format )
                            , ( "attachment_ids", attachmentIds )
                            ]
                        )
                    )

                EditPost postId ->
                    ( "PATCH"
                    , "/api/v1/posts/" ++ urlEncode postId
                    , "{\"expected_version\":"
                        ++ Maybe.withDefault "0" editor.version
                        ++ ",\"title\":"
                        ++ Encode.encode 0 (Encode.string editor.title)
                        ++ ",\"body\":"
                        ++ Encode.encode 0 (Encode.string editor.body)
                        ++ ",\"content_format\":"
                        ++ Encode.encode 0 (Encode.string editor.format)
                        ++ ",\"attachment_ids\":"
                        ++ Encode.encode 0 attachmentIds
                        ++ "}"
                    )
    in
    ( { model | editor = Just { editor | saving = True, problem = Nothing } }
    , Api.send model.csrf method url encodedBody (ActionDone (SaveEditorAction editor.mode) model.routeEpoch)
    )


manageRequest : Model -> String -> String -> String -> String -> ( Model, Cmd Msg )
manageRequest model key method url body =
    if Set.member key model.busy then
        ( model, Cmd.none )

    else
        ( { model | busy = Set.insert key model.busy }
        , Api.send model.csrf method url body (ActionDone (ManageAction key) model.routeEpoch)
        )


manageActorRequest : Model -> String -> String -> String -> ( Model, Cmd Msg )
manageActorRequest model key method section =
    case model.manage of
        Just manage ->
            manageActorRequestWith model key method section manage.actor

        Nothing ->
            ( model, Cmd.none )


manageActorRequestFor : Model -> String -> String -> String -> String -> ( Model, Cmd Msg )
manageActorRequestFor model key method section actor =
    manageActorRequestWith model key method section actor


manageActorRequestWith : Model -> String -> String -> String -> String -> ( Model, Cmd Msg )
manageActorRequestWith model key method section actor =
    manageRequest model
        key
        method
        ("/api/v1/communities/" ++ urlEncode (communityId model.route) ++ "/" ++ section)
        (Encode.encode 0 (Encode.object [ ( "actor", Encode.string actor ) ]))


managePage : Model -> Bool -> Int -> ( Model, Cmd Msg )
managePage model members delta =
    case model.manage of
        Just manage ->
            let
                updated =
                    if members then
                        { manage | memberOffset = max 0 (manage.memberOffset + delta) }

                    else
                        { manage | managerOffset = max 0 (manage.managerOffset + delta) }
            in
            case model.route of
                Route.Manage id ->
                    loadManageState model.routeEpoch id updated model

                _ ->
                    ( model, Cmd.none )

        Nothing ->
            ( model, Cmd.none )


managePostRequest : Model -> String -> ManagePostAction -> ( Model, Cmd Msg )
managePostRequest model postId action =
    let
        id =
            communityId model.route

        key =
            "manage-post-" ++ postId ++ "-" ++ manageActionKey action

        ( method, url, body ) =
            case action of
                RemoveCommunityPost ->
                    ( "POST", "/api/v1/communities/" ++ urlEncode id ++ "/removals", Encode.object [ ( "post_id", Encode.string postId ) ] )

                RestoreCommunityPost ->
                    ( "DELETE", "/api/v1/communities/" ++ urlEncode id ++ "/removals", Encode.object [ ( "post_id", Encode.string postId ) ] )

                HideSitePost ->
                    ( "POST", "/api/v1/posts/" ++ urlEncode postId ++ "/hide", Encode.object [] )

                UnhideSitePost ->
                    ( "DELETE", "/api/v1/posts/" ++ urlEncode postId ++ "/hide", Encode.object [] )

                ImportSitePost ->
                    ( "POST", "/api/v1/posts/" ++ urlEncode postId ++ "/import", Encode.object [] )

                AcceptSubmission ->
                    ( "POST", "/api/v1/communities/" ++ urlEncode id ++ "/submissions", Encode.object [ ( "post_id", Encode.string postId ), ( "state", Encode.string "accepted" ) ] )

                RejectSubmission ->
                    ( "POST", "/api/v1/communities/" ++ urlEncode id ++ "/submissions", Encode.object [ ( "post_id", Encode.string postId ), ( "state", Encode.string "rejected" ) ] )

                BackfillDiscussion ->
                    let
                        context =
                            model.manage |> Maybe.map .contextId |> Maybe.withDefault ""
                    in
                    ( "POST", "/api/v1/contexts/" ++ urlEncode context ++ "/backfill", Encode.object [] )
    in
    manageRequest model key method url (Encode.encode 0 body)


applyLike : String -> Bool -> Model -> Model
applyLike id wasLiked model =
    let
        transform post =
            if post.id == id then
                { post
                    | liked = not wasLiked
                    , likes =
                        max 0
                            (post.likes
                                + (if wasLiked then
                                    -1

                                   else
                                    1
                                  )
                            )
                }

            else
                post

        page remote =
            Remote.map (\data -> { data | items = List.map transform data.items }) remote

        searchState =
            model.search
    in
    { model
        | post = Remote.map transform model.post
        , replies = page model.replies
        , topics = page model.topics
        , communityTopics = page model.communityTopics
        , nestedReplies = Dict.map (\_ value -> page value) model.nestedReplies
        , search =
            case model.search.results of
                Ready (PostSearch data) ->
                    { searchState | results = Ready (PostSearch { data | items = List.map transform data.items }) }

                _ ->
                    model.search
    }


authProblem : Model -> Api.Problem -> Model
authProblem model problem =
    if problem.status == 401 then
        clearPrivate
            { model
                | auth = Anonymous
                , authGeneration = model.authGeneration + 1
                , csrf = ""
                , flash = FlashProblem problem
            }

    else
        model


problemState : Model -> Api.Problem -> Model
problemState model problem =
    let
        base =
            authProblem model problem
    in
    { base | flash = FlashProblem problem }


clearPrivate : Model -> Model
clearPrivate model =
    { model
        | ownProfile = NotAsked
        , notifications = NotAsked
        , unreadCount = Nothing
        , profileForm = emptyProfileForm
        , manage = Nothing
        , busy = Set.empty
    }


receiveIncoming : Decode.Value -> Model -> ( Model, Cmd Msg )
receiveIncoming raw model =
    case Decode.decodeValue incomingDecoder raw of
        Ok (IncomingCsrf value) ->
            ( { model | csrf = value }, Cmd.none )

        Ok (IncomingFormatting currentFormatting) ->
            case model.active of
                Just active ->
                    if currentFormatting.locale == Locale.code active.locale then
                        ( { model | formatted = Just currentFormatting }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        Ok IncomingIgnored ->
            ( model, Cmd.none )

        Err _ ->
            ( model, Cmd.none )


type IncomingData
    = IncomingCsrf String
    | IncomingFormatting Formatting
    | IncomingIgnored


incomingDecoder : Decode.Decoder IncomingData
incomingDecoder =
    Decode.field "kind" Decode.string
        |> Decode.andThen
            (\kind ->
                case kind of
                    "csrf" ->
                        Decode.map IncomingCsrf (Decode.field "value" Decode.string)

                    "formatted" ->
                        Decode.map IncomingFormatting formattingDecoder

                    _ ->
                        Decode.succeed IncomingIgnored
            )


type alias Formatting =
    { locale : String
    , source : String
    , absolute : String
    , relative : String
    , numbers : List ( Int, String )
    , plurals : List ( Int, String )
    }


formattingDecoder : Decode.Decoder Formatting
formattingDecoder =
    Decode.map6 Formatting
        (Decode.field "locale" Decode.string)
        (Decode.at [ "times", "0", "source" ] Decode.string)
        (Decode.at [ "times", "0", "absolute" ] Decode.string)
        (Decode.at [ "times", "0", "relative" ] Decode.string)
        (Decode.field "numbers" (Decode.list pairedIntString))
        (Decode.field "plurals" (Decode.list pairedIntString))


pairedIntString : Decode.Decoder ( Int, String )
pairedIntString =
    Decode.oneOf
        [ Decode.map2 Tuple.pair (Decode.field "source" Decode.int) (Decode.field "text" Decode.string)
        , Decode.map2 Tuple.pair (Decode.field "source" Decode.int) (Decode.field "category" Decode.string)
        ]


requestCsrf : Cmd Msg
requestCsrf =
    outgoing (Encode.object [ ( "action", Encode.string "csrf" ) ])


setLocale : Locale -> Cmd Msg
setLocale locale =
    outgoing
        (Encode.object
            [ ( "action", Encode.string "locale" )
            , ( "locale", Encode.string (Locale.code locale) )
            ]
        )


requestFormatting : Locale -> Cmd Msg
requestFormatting locale =
    outgoing
        (Encode.object
            [ ( "action", Encode.string "format" )
            , ( "locale", Encode.string (Locale.code locale) )
            , ( "times", Encode.list Encode.string [ "2026-10-20T08:30:00Z" ] )
            , ( "numbers", Encode.list Encode.int [ 1, 3, 1234567 ] )
            , ( "plurals", Encode.list Encode.int [ 1, 3 ] )
            ]
        )


focus : String -> Cmd Msg
focus identifier =
    outgoing (Encode.object [ ( "action", Encode.string "focus" ), ( "id", Encode.string identifier ) ])


openDialog : String -> Cmd Msg
openDialog identifier =
    outgoing (Encode.object [ ( "action", Encode.string "dialog-open" ), ( "id", Encode.string identifier ) ])


closeDialog : String -> Cmd Msg
closeDialog identifier =
    outgoing (Encode.object [ ( "action", Encode.string "dialog-close" ), ( "id", Encode.string identifier ) ])


emptyEditor : EditorMode -> EditorState
emptyEditor mode =
    { mode = mode
    , title = ""
    , body = ""
    , format = "markdown"
    , version = Nothing
    , attachments = []
    , uploading = False
    , saving = False
    , problem = Nothing
    , conflict = Nothing
    }


sourceAttachments : Domain.Source -> List EditorAttachment
sourceAttachments source =
    List.map (\id -> { id = id, name = id, reference = "/api/v1/media/" ++ id }) source.attachments


emptyProfileForm : ProfileForm
emptyProfileForm =
    { displayName = "", biography = "", avatar = KeepAvatar, avatarUrl = "", uploading = False, saving = False, problem = Nothing }


profileFormFrom : Domain.Profile -> ProfileForm
profileFormFrom profile =
    { displayName = profile.name
    , biography = profile.biography
    , avatar = KeepAvatar
    , avatarUrl = profile.avatar
    , uploading = False
    , saving = False
    , problem = Nothing
    }


emptyCommunityForm : CommunityForm
emptyCommunityForm =
    { name = "", title = "", mode = "federated", readPolicy = "eligible_users", postPolicy = "eligible_users", busy = False, problem = Nothing }


normalizePolicies : CommunityForm -> CommunityForm
normalizePolicies form =
    if form.postPolicy == "eligible_users" && form.readPolicy == "members" then
        { form | readPolicy = "eligible_users" }

    else
        form


normalizeManagePolicies : ManageState -> ManageState
normalizeManagePolicies manage =
    if manage.postPolicy == "eligible_users" && manage.readPolicy == "members" then
        { manage | readPolicy = "eligible_users" }

    else
        manage


emptySearch : SearchState
emptySearch =
    { kind = "posts", query = "", results = NotAsked }


emptyManage : ManageState
emptyManage =
    { community = NotAsked
    , members = NotAsked
    , managers = NotAsked
    , memberOffset = 0
    , managerOffset = 0
    , actor = ""
    , postId = ""
    , contextId = ""
    , readPolicy = "eligible_users"
    , postPolicy = "eligible_users"
    , problem = Nothing
    }


setEditor : Model -> (EditorState -> EditorState) -> Cmd Msg -> ( Model, Cmd Msg )
setEditor model transform command =
    ( { model | editor = Maybe.map transform model.editor }, command )


setManage : Model -> (ManageState -> ManageState) -> Cmd Msg -> ( Model, Cmd Msg )
setManage model transform command =
    ( { model | manage = Maybe.map transform model.manage }, command )


updateManageRecord : Model -> (ManageState -> ManageState) -> Model
updateManageRecord model transform =
    { model | manage = Maybe.map transform model.manage }


communityId : Route.Route -> String
communityId route =
    case route of
        Route.Community id ->
            id

        Route.NewTopic id ->
            id

        Route.Manage id ->
            id

        _ ->
            ""


likeKey : String -> String
likeKey id =
    "like-" ++ id


manageActionKey : ManagePostAction -> String
manageActionKey action =
    case action of
        RemoveCommunityPost ->
            "remove"

        RestoreCommunityPost ->
            "restore"

        HideSitePost ->
            "hide"

        UnhideSitePost ->
            "unhide"

        ImportSitePost ->
            "import"

        AcceptSubmission ->
            "accept"

        RejectSubmission ->
            "reject"

        BackfillDiscussion ->
            "backfill"


deleteTriggerId : String -> String
deleteTriggerId id =
    "delete-post-" ++ id


urlEncode : String -> String
urlEncode value =
    Url.percentEncode value


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
                viewReady model active
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
            case model.community of
                Ready community ->
                    community.title

                _ ->
                    Translations.communitiesTitle texts

        Route.Post _ ->
            case model.post of
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


viewBoot : Model -> Html Msg
viewBoot model =
    div [ A.class "app-shell" ]
        [ main_ [ A.id "main-content", A.class "boot-shell" ]
            [ h1 [ A.id "main-heading", A.tabindex -1, A.class "boot-brand" ] [ text "Commune" ]
            , if model.bootFailed then
                bootFailure model

              else
                div [ A.class "boot-progress", A.attribute "role" "progressbar", A.attribute "aria-label" "Commune" ]
                    [ div [ A.class "loading-dot", A.attribute "aria-hidden" "true" ] [] ]
            ]
        ]


bootFailure : Model -> Html Msg
bootFailure model =
    section [ A.class "card error-shell", A.attribute "aria-labelledby" "boot-error-title" ]
        [ h2 [ A.id "boot-error-title" ] [ text "Interface translations are unavailable" ]
        , p [] [ text "Check your connection, then retry or choose another language." ]
        , label [ A.for "boot-language-select" ] [ text "Language" ]
        , languageSelect "boot-language-select" BootLanguageSelected model.requested
        , button [ A.class "filled-button", Events.onClick RetryLocalization ] [ text "Try again" ]
        ]


viewReady : Model -> Active -> Html Msg
viewReady model active =
    div [ A.class "app-shell" ]
        [ a [ A.href "#main-content", A.class "skip-link" ] [ text (Translations.skipLink active.texts) ]
        , viewTopBar model active
        , viewLocaleNotice model active
        , viewFlash model active
        , main_ [ A.id "main-content", A.class "page-grid", A.tabindex -1 ]
            [ pageView model active ]
        , viewDrawer model active
        , viewConfirmation model active
        ]


viewTopBar : Model -> Active -> Html Msg
viewTopBar model active =
    header [ A.class "top-bar" ]
        [ button
            [ A.id "menu-button"
            , A.class "icon-button compact-menu"
            , A.attribute "aria-expanded" (boolText model.drawerOpen)
            , A.attribute "aria-controls" "navigation-drawer"
            , Events.onClick OpenDrawer
            ]
            [ span [ A.attribute "aria-hidden" "true" ] [ text "☰" ]
            , span [ A.class "sr-only" ] [ text (Translations.openMenu active.texts) ]
            ]
        , a [ A.href "/", A.class "brand" ] [ text (Translations.appTitle active.texts) ]
        , nav [ A.class "desktop-nav", A.attribute "aria-label" (Translations.mainNavigation active.texts) ]
            (navLinks model active [] True)
        , div [ A.class "language-control" ]
            [ case model.auth of
                Authenticated identity ->
                    span [ A.class "identity-label" ] [ text (signedInLabel active.texts identity) ]

                _ ->
                    text ""
            , label [ A.for "language-select" ] [ text (Translations.languageLabel active.texts) ]
            , languageSelect "language-select" LanguageSelected active.locale
            , pendingIndicator model active
            ]
        ]


navLinks : Model -> Active -> List (Html.Attribute Msg) -> Bool -> List (Html Msg)
navLinks model active extras includeAccount =
    let
        texts =
            active.texts

        notificationText =
            case model.unreadCount of
                Just count ->
                    Translations.navNotifications texts ++ " (" ++ count ++ ")"

                Nothing ->
                    Translations.navNotifications texts

        account =
            case model.auth of
                Authenticated identity ->
                    [ a (A.href (Route.path (Route.Profile identity.username)) :: extras)
                        [ text (Translations.navProfile texts) ]
                    , a (A.href (Route.path Route.Settings) :: extras)
                        [ text (Translations.navSettings texts) ]
                    , button (A.class "link-button" :: Events.onClick Logout :: extras)
                        [ text (Translations.logout texts) ]
                    ]

                _ ->
                    [ a (A.href (Route.path Route.Login) :: extras)
                        [ text (Translations.navLogin texts) ]
                    ]
    in
    [ navLink model Route.Latest extras (Translations.navLatest texts)
    , navLink model Route.Communities extras (Translations.navCommunities texts)
    , navLink model Route.Search extras (Translations.navSearch texts)
    , navLink model Route.Notifications extras notificationText
    ]
        ++ (if includeAccount then
                account

            else
                []
           )


navLink : Model -> Route.Route -> List (Html.Attribute Msg) -> String -> Html Msg
navLink model target extras label =
    a
        (A.href (Route.path target)
            :: extras
            ++ (if model.route == target then
                    [ A.attribute "aria-current" "page" ]

                else
                    []
               )
        )
        [ text label ]


viewDrawer : Model -> Active -> Html Msg
viewDrawer model active =
    if model.drawerOpen then
        Html.node "dialog"
            [ A.id "navigation-drawer"
            , A.class "drawer"
            , A.attribute "aria-labelledby" "drawer-title"
            , Events.on "close" (Decode.succeed DrawerClosed)
            , Events.on "cancel" (Decode.succeed CloseDrawer)
            ]
            [ button [ A.class "icon-button drawer-close", Events.onClick CloseDrawer ]
                [ span [ A.attribute "aria-hidden" "true" ] [ text "×" ]
                , span [ A.class "sr-only" ] [ text (Translations.closeMenu active.texts) ]
                ]
            , h2 [ A.id "drawer-title" ] [ text (Translations.mainNavigation active.texts) ]
            , nav [ A.attribute "aria-label" (Translations.mainNavigation active.texts), A.class "drawer-nav" ]
                (navLinks model active [ Events.onClick CloseDrawer ] True)
            ]

    else
        text ""


viewConfirmation : Model -> Active -> Html Msg
viewConfirmation model active =
    case model.dialog of
        Just postId ->
            Html.node "dialog"
                [ A.id "confirmation-dialog"
                , A.class "confirmation"
                , A.attribute "aria-labelledby" "confirmation-title"
                , Events.on "close" (Decode.succeed CloseDialog)
                , Events.on "cancel" (Decode.succeed CloseDialog)
                ]
                [ h2 [ A.id "confirmation-title" ] [ text (Translations.confirmDeleteTitle active.texts) ]
                , p [] [ text (Translations.confirmDeleteHelp active.texts) ]
                , div [ A.class "dialog-actions" ]
                    [ button [ A.class "text-button", Events.onClick CloseDialog ] [ text (Translations.cancel active.texts) ]
                    , button [ A.class "danger-button", Events.onClick (ConfirmDelete postId) ] [ text (Translations.deletePost active.texts) ]
                    ]
                ]

        Nothing ->
            text ""


viewFlash : Model -> Active -> Html Msg
viewFlash model active =
    case model.flash of
        NoFlash ->
            text ""

        flash ->
            div [ A.class "notice", A.attribute "role" "status", A.attribute "aria-live" "polite" ]
                [ p [] [ text (flashText active.texts flash) ]
                , button [ A.class "text-button", Events.onClick DismissFlash ] [ text (Translations.closeLabel active.texts) ]
                ]


viewLocaleNotice : Model -> Active -> Html Msg
viewLocaleNotice model active =
    let
        notice =
            model.loading.notice

        content =
            case notice of
                Localization.None ->
                    []

                Localization.Changed target ->
                    [ text (Translations.languageSwitchSuccess (Locale.label target) active.texts) ]

                Localization.Failed target ->
                    [ text (Translations.languageSwitchFailed (Locale.label target) active.texts) ]

                Localization.FallbackNotice target ->
                    [ text (Translations.languageFallbackNotice (Locale.label target) active.texts) ]
    in
    if List.isEmpty content then
        text ""

    else
        div [ A.class "notice", A.attribute "role" "status", A.attribute "aria-live" "polite" ]
            [ p [] content
            , case notice of
                Localization.Failed _ ->
                    button [ A.class "text-button", Events.onClick RetryLocalization ]
                        [ text (Translations.retryLabel active.texts) ]

                Localization.FallbackNotice _ ->
                    button [ A.class "text-button", Events.onClick RetryLocalization ]
                        [ text (Translations.retryLabel active.texts) ]

                _ ->
                    text ""
            ]


flashText : Translations.I18n -> Flash -> String
flashText texts flash =
    case flash of
        FlashProblem problem ->
            problemText texts problem

        FlashSaved ->
            Translations.saved texts

        FlashCreated ->
            Translations.created texts

        FlashDeleted ->
            Translations.deleted texts

        FlashLoggedOut ->
            Translations.loggedOut texts

        FlashVerificationSuccess ->
            Translations.verificationSuccess texts

        FlashRegistrationAccepted ->
            Translations.registrationAccepted texts

        FlashUploaded ->
            Translations.uploadComplete texts

        FlashUploadFailed ->
            Translations.uploadFailed texts

        NoFlash ->
            ""


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
            pageEditor model active (CreateTopic id)

        Route.EditPost id ->
            pageEditor model active (EditPost id)

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


pageHeading : String -> Html Msg -> Html Msg
pageHeading title content =
    section [ A.class "primary-column" ]
        [ h1 [ A.id "main-heading", A.tabindex -1, A.dir "auto" ] [ text title ]
        , content
        ]


pageLatest : Model -> Active -> Html Msg
pageLatest model active =
    pageHeading (Translations.latestTitle active.texts)
        (viewRemote active.texts
            model.topics
            (\page ->
                if List.isEmpty page.items then
                    emptyWithPagination active.texts model.url page

                else
                    div [ A.class "stack" ]
                        [ div [ A.class "stack" ] (List.map (postCard model active) page.items)
                        , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                        ]
            )
        )


pageCommunities : Model -> Active -> Html Msg
pageCommunities model active =
    pageHeading (Translations.communitiesTitle active.texts)
        (section [ A.class "stack" ]
            [ p [ A.class "muted" ] [ text (Translations.communitiesIntro active.texts) ]
            , viewRemote active.texts
                model.communities
                (\page ->
                    if List.isEmpty page.items then
                        emptyWithPagination active.texts model.url page

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map (communityCard active) page.items)
                            , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                            ]
                )
            ]
        )


communityCard : Active -> Domain.Community -> Html Msg
communityCard active community =
    article [ A.class "card" ]
        [ h2 [] [ a [ A.href (Route.path (Route.Community community.id)) ] [ text community.title ] ]
        , if String.isEmpty community.description then
            text ""

          else
            p [ A.dir "auto" ] [ text community.description ]
        , p [ A.class "metadata" ]
            [ text
                (Translations.policySummary
                    { read = policyLabel active.texts community.readPolicy
                    , post = policyLabel active.texts community.postPolicy
                    }
                    active.texts
                )
            ]
        , p [ A.class "chips" ]
            [ span [ A.class "chip" ] [ text (modeLabel active.texts community.mode) ]
            , span [ A.class "chip" ] [ text (policyLabel active.texts community.readPolicy) ]
            ]
        ]


pageCommunity : Model -> Active -> String -> Html Msg
pageCommunity model active id =
    pageHeading
        (case model.community of
            Ready community ->
                community.title

            _ ->
                Translations.communitiesTitle active.texts
        )
        (section [ A.class "primary-column" ]
            [ viewRemote active.texts
                model.community
                (\community ->
                    div [ A.class "stack" ]
                        [ p [ A.class "metadata" ]
                            [ text
                                (Translations.policySummary
                                    { read = policyLabel active.texts community.readPolicy
                                    , post = policyLabel active.texts community.postPolicy
                                    }
                                    active.texts
                                )
                            ]
                        , if String.isEmpty community.description then
                            text ""

                          else
                            p [ A.dir "auto" ] [ text community.description ]
                        , div [ A.class "actions" ]
                            [ if community.canPost then
                                a [ A.class "filled-button", A.href (Route.path (Route.NewTopic community.id)) ]
                                    [ text (Translations.publishTopic active.texts) ]

                              else
                                text ""
                            , if community.canManage then
                                a [ A.class "outlined-button", A.href (Route.path (Route.Manage community.id)) ]
                                    [ text (Translations.manageTitle active.texts) ]

                              else
                                text ""
                            ]
                        ]
                )
            , h2 [] [ text (Translations.latestTitle active.texts) ]
            , viewRemote active.texts
                model.communityTopics
                (\page ->
                    if List.isEmpty page.items then
                        emptyWithPagination active.texts model.url page

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map (postCard model active) page.items)
                            , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                            ]
                )
            ]
        )


pagePost : Model -> Active -> String -> Html Msg
pagePost model active postId =
    pageHeading
        (case model.post of
            Ready post ->
                if String.isEmpty post.title then
                    Translations.repliesTitle active.texts

                else
                    post.title

            _ ->
                Translations.repliesTitle active.texts
        )
        (section [ A.class "primary-column" ]
            [ viewRemote active.texts
                model.post
                (\post ->
                    div [ A.class "stack" ]
                        [ postCard model active post
                        , if post.canReply && post.deleted == False then
                            button [ A.class "filled-button", Events.onClick (StartReply post.id) ]
                                [ text (Translations.reply active.texts) ]

                          else
                            text ""
                        , case model.editor of
                            Just editor ->
                                case editor.mode of
                                    CreateReply parent ->
                                        viewEditor model active editor

                                    _ ->
                                        text ""

                            Nothing ->
                                text ""
                        ]
                )
            , h2 [] [ text (Translations.repliesTitle active.texts) ]
            , viewRemote active.texts
                model.replies
                (\page ->
                    if List.isEmpty page.items then
                        emptyWithPagination active.texts model.url page

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map (postCard model active) page.items)
                            , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                            ]
                )
            ]
        )


postCard : Model -> Active -> Domain.Post -> Html Msg
postCard model active post =
    article [ A.class "card post-card", A.attribute "aria-labelledby" ("post-" ++ post.id) ]
        [ h2 [ A.id ("post-" ++ post.id), A.dir "auto" ]
            [ a [ A.href (Route.path (Route.Post post.id)) ]
                [ text
                    (if String.isEmpty post.title then
                        Translations.repliesTitle active.texts

                     else
                        post.title
                    )
                ]
            ]
        , p [ A.class "metadata" ]
            [ bdi [] [ text (Translations.authorLabel post.author active.texts) ]
            , text " · "
            , time [ A.datetime post.date, A.attribute "data-commune-time" "" ] [ text (formattedDate model post.date) ]
            ]
        , Ui.Rich.view post.html
        , viewAttachments active post.attachments
        , div [ A.class "post-actions" ]
            [ button
                [ A.class "text-button"
                , A.disabled (not post.canLike || Set.member (likeKey post.id) model.busy)
                , Events.onClick (ToggleLike post.id post.liked)
                ]
                [ text
                    ((if post.liked then
                        Translations.unlikeAction active.texts

                      else
                        Translations.likeAction active.texts
                     )
                        ++ " · "
                        ++ likesLabel model active.texts post.likes
                    )
                ]
            , if post.canEdit then
                a [ A.class "text-button", A.href (Route.path (Route.EditPost post.id)) ]
                    [ text (Translations.editPost active.texts) ]

              else
                text ""
            , if post.canDelete then
                button
                    [ A.id (deleteTriggerId post.id)
                    , A.class "text-button danger-text"
                    , Events.onClick (OpenDeleteDialog post.id)
                    ]
                    [ text (Translations.deletePost active.texts) ]

              else
                text ""
            , if post.replies > 0 then
                button [ A.class "text-button", Events.onClick (ToggleReplies post.id), A.attribute "aria-expanded" (boolText (Set.member post.id model.expandedReplies)) ]
                    [ text (repliesLabel model active.texts post.replies) ]

              else
                text ""
            ]
        , if Set.member post.id model.expandedReplies then
            viewNested active post.id model

          else
            text ""
        ]


viewNested : Active -> String -> Model -> Html Msg
viewNested active parent model =
    case Dict.get parent model.nestedReplies of
        Just nested ->
            viewRemote active.texts
                nested
                (\page ->
                    div [ A.class "nested" ]
                        (if List.isEmpty page.items then
                            [ p [ A.class "muted" ] [ text (Translations.noReplies active.texts) ] ]

                         else
                            List.map (postCard model active) page.items
                        )
                )

        Nothing ->
            text ""


viewAttachments : Active -> List Domain.Attachment -> Html Msg
viewAttachments active attachments =
    if List.isEmpty attachments then
        text ""

    else
        section [ A.class "attachments" ]
            [ h3 [] [ text (Translations.attachments active.texts) ]
            , ul []
                (List.map
                    (\attachment ->
                        li []
                            [ a [ A.href attachment.url, A.rel "noopener noreferrer" ]
                                [ text
                                    (if String.isEmpty attachment.name then
                                        attachment.mediaType

                                     else
                                        attachment.name
                                    )
                                ]
                            ]
                    )
                    attachments
                )
            ]


pageEditor : Model -> Active -> EditorMode -> Html Msg
pageEditor model active mode =
    let
        title =
            case mode of
                CreateTopic _ ->
                    Translations.publishTopic active.texts

                CreateReply _ ->
                    Translations.publishReply active.texts

                EditPost _ ->
                    Translations.editPost active.texts
    in
    pageHeading title
        (case model.auth of
            Authenticated _ ->
                section [ A.class "primary-column" ]
                    [ case model.editor of
                        Just editor ->
                            viewEditor model active editor

                        Nothing ->
                            viewRemote active.texts
                                model.source
                                (\_ -> p [ A.class "muted" ] [ text (Translations.loadingMessage active.texts) ])
                    ]

            _ ->
                loginRequired active.texts
        )


viewEditor : Model -> Active -> EditorState -> Html Msg
viewEditor model active editor =
    form [ Events.onSubmit EditorSubmit, A.class "card form-stack" ]
        [ case editor.mode of
            CreateReply _ ->
                text ""

            EditPost _ ->
                if String.isEmpty editor.title then
                    text ""

                else
                    editorTitle active editor

            CreateTopic _ ->
                editorTitle active editor
        , div []
            [ label [ A.for "editor-body" ] [ text (Translations.topicBody active.texts) ]
            , textarea
                [ A.id "editor-body"
                , A.value editor.body
                , A.dir "auto"
                , A.required True
                , A.attribute "aria-describedby" "editor-help"
                , Events.onInput EditorBodyChanged
                ]
                []
            , p [ A.id "editor-help", A.class "muted" ] [ text (Translations.topicBodyHelp active.texts) ]
            ]
        , div []
            [ label [ A.for "editor-format" ] [ text (Translations.contentFormat active.texts) ]
            , select [ A.id "editor-format", Events.on "change" (Decode.map EditorFormatChanged (Decode.at [ "target", "value" ] Decode.string)) ]
                [ option [ A.value "markdown", A.selected (editor.format == "markdown") ] [ text (Translations.markdown active.texts) ]
                , option [ A.value "legacy", A.selected (editor.format == "legacy") ] [ text (Translations.originalFormat active.texts) ]
                ]
            ]
        , div []
            [ label [ A.for "editor-file" ] [ text (Translations.uploadFile active.texts) ]
            , input
                [ A.id "editor-file"
                , A.type_ "file"
                , Events.on "change" (Decode.maybe (Decode.at [ "target", "files", "0" ] File.decoder) |> Decode.map EditorFileSelected)
                ]
                []
            , p [ A.class "muted" ] [ text (Translations.attachmentHelp active.texts) ]
            , p [ A.class "muted" ] [ text (Translations.imageDescriptionHelp active.texts) ]
            , if editor.uploading then
                p [ A.attribute "role" "status" ] [ text (Translations.loadingMessage active.texts) ]

              else
                text ""
            , ul [ A.class "attachment-list" ]
                (List.map
                    (\attachment ->
                        li []
                            [ text
                                (if String.isEmpty attachment.name then
                                    attachment.id

                                 else
                                    attachment.name
                                )
                            , button [ A.type_ "button", A.class "text-button", Events.onClick (EditorRemoveAttachment attachment.id) ]
                                [ text (Translations.remove active.texts) ]
                            ]
                    )
                    editor.attachments
                )
            ]
        , case editor.problem of
            Just problem ->
                div [ A.class "field-error", A.attribute "role" "alert" ] [ text (problemText active.texts problem) ]

            Nothing ->
                text ""
        , case editor.conflict of
            Just source ->
                section [ A.class "conflict-panel" ]
                    [ h3 [] [ text (Translations.latestSource active.texts) ]
                    , pre [ A.dir "auto" ] [ text source.body ]
                    , div [ A.class "actions" ]
                        [ button [ A.type_ "button", A.class "outlined-button", Events.onClick EditorKeepDraft ]
                            [ text (Translations.keepDraft active.texts) ]
                        , button [ A.type_ "button", A.class "filled-button", Events.onClick EditorUseLatest ]
                            [ text (Translations.useLatest active.texts) ]
                        ]
                    ]

            Nothing ->
                text ""
        , button [ A.type_ "submit", A.class "filled-button", A.disabled editor.saving ]
            [ text
                (case editor.mode of
                    CreateTopic _ ->
                        Translations.publishTopic active.texts

                    CreateReply _ ->
                        Translations.publishReply active.texts

                    EditPost _ ->
                        Translations.saveChanges active.texts
                )
            ]
        ]


editorTitle : Active -> EditorState -> Html Msg
editorTitle active editor =
    div []
        [ label [ A.for "editor-title" ] [ text (Translations.topicTitle active.texts) ]
        , input [ A.id "editor-title", A.type_ "text", A.required True, A.value editor.title, Events.onInput EditorTitleChanged ]
            []
        ]


pageLogin : Model -> Active -> Html Msg
pageLogin model active =
    pageHeading (Translations.loginTitle active.texts)
        (section [ A.class "primary-column" ]
            [ case model.auth of
                Authenticated identity ->
                    p [] [ text (Translations.signedInAs identity.username active.texts) ]

                _ ->
                    form [ Events.onSubmit LoginSubmitted, A.class "card form-stack" ]
                        [ p [ A.class "muted" ] [ text (Translations.loginHelp active.texts) ]
                        , div []
                            [ label [ A.for "login-identifier" ] [ text (Translations.loginIdentifier active.texts) ]
                            , input
                                [ A.id "login-identifier"
                                , A.type_ "text"
                                , A.attribute "autocomplete" "username"
                                , A.required True
                                , A.attribute "aria-describedby" "login-error"
                                , A.attribute "aria-invalid" (boolText (model.loginProblem /= Nothing))
                                , A.value model.loginIdentifier
                                , Events.onInput LoginIdentifierChanged
                                ]
                                []
                            ]
                        , div []
                            [ label [ A.for "login-password" ] [ text (Translations.password active.texts) ]
                            , input
                                [ A.id "login-password"
                                , A.type_ "password"
                                , A.attribute "autocomplete" "current-password"
                                , A.required True
                                , A.attribute "aria-describedby" "login-error"
                                , A.attribute "aria-invalid" (boolText (model.loginProblem /= Nothing))
                                , A.value model.loginPassword
                                , Events.onInput LoginPasswordChanged
                                ]
                                []
                            ]
                        , viewFormProblemWithId active.texts
                            "login-error"
                            (Maybe.map
                                (\problem ->
                                    if problem.status == 401 then
                                        Translations.invalidCredentials active.texts

                                    else
                                        problemText active.texts problem
                                )
                                model.loginProblem
                            )
                        , button [ A.type_ "submit", A.class "filled-button", A.disabled model.loginBusy ]
                            [ text (Translations.loginSubmit active.texts) ]
                        , p []
                            [ text (Translations.noAccount active.texts)
                            , text " "
                            , a [ A.href (Route.path Route.Register) ] [ text (Translations.registerTitle active.texts) ]
                            ]
                        ]
            ]
        )


pageRegister : Model -> Active -> Html Msg
pageRegister model active =
    pageHeading (Translations.registerTitle active.texts)
        (form [ Events.onSubmit RegisterSubmitted, A.class "card form-stack" ]
            [ p [ A.class "muted" ] [ text (Translations.registerHelp active.texts) ]
            , div []
                [ label [ A.for "register-username" ] [ text (Translations.username active.texts) ]
                , input
                    [ A.id "register-username"
                    , A.type_ "text"
                    , A.attribute "autocomplete" "username"
                    , A.required True
                    , A.attribute "aria-describedby" "register-error"
                    , A.attribute "aria-invalid" (boolText (model.registerProblem /= Nothing))
                    , A.value model.registerUsername
                    , Events.onInput RegisterUsernameChanged
                    ]
                    []
                ]
            , div []
                [ label [ A.for "register-email" ] [ text (Translations.email active.texts) ]
                , input
                    [ A.id "register-email"
                    , A.type_ "email"
                    , A.attribute "autocomplete" "email"
                    , A.required True
                    , A.attribute "aria-describedby" "register-error"
                    , A.attribute "aria-invalid" (boolText (model.registerProblem /= Nothing))
                    , A.value model.registerEmail
                    , Events.onInput RegisterEmailChanged
                    ]
                    []
                ]
            , viewFormProblemWithId active.texts "register-error" (Maybe.map (problemText active.texts) model.registerProblem)
            , button [ A.type_ "submit", A.class "filled-button", A.disabled model.registerBusy ]
                [ text (Translations.registerSubmit active.texts) ]
            , button [ A.type_ "button", A.class "text-button", Events.onClick ResendSubmitted ]
                [ text (Translations.resendVerification active.texts) ]
            ]
        )


pageVerify : Model -> Active -> Html Msg
pageVerify model active =
    pageHeading (Translations.verifyTitle active.texts)
        (section [ A.class "card form-stack" ]
            [ if model.verified then
                div [ A.class "notice", A.attribute "role" "status" ]
                    [ p [] [ text (Translations.verificationSuccess active.texts) ]
                    , a [ A.href (Route.path Route.Login) ] [ text (Translations.loginSubmit active.texts) ]
                    ]

              else if String.isEmpty model.verificationToken then
                div [ A.class "field-error", A.attribute "role" "alert" ]
                    [ text (Translations.verificationMissing active.texts) ]

              else
                form [ Events.onSubmit VerifySubmitted, A.class "form-stack" ]
                    [ p [ A.class "muted" ] [ text (Translations.verifyHelp active.texts) ]
                    , div []
                        [ label [ A.for "verify-password" ] [ text (Translations.password active.texts) ]
                        , input
                            [ A.id "verify-password"
                            , A.type_ "password"
                            , A.attribute "autocomplete" "new-password"
                            , A.required True
                            , A.attribute "aria-describedby" "verify-error"
                            , A.attribute "aria-invalid" (boolText (model.verifyProblem /= Nothing))
                            , A.value model.verifyPassword
                            , Events.onInput VerifyPasswordChanged
                            ]
                            []
                        ]
                    , viewFormProblemWithId active.texts "verify-error" (Maybe.map (problemText active.texts) model.verifyProblem)
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled model.verifyBusy ]
                        [ text (Translations.verifySubmit active.texts) ]
                    ]
            ]
        )


pageSearch : Model -> Active -> Html Msg
pageSearch model active =
    pageHeading (Translations.searchTitle active.texts)
        (section [ A.class "primary-column" ]
            [ form [ Events.onSubmit SearchSubmitted, A.class "card form-stack" ]
                [ p [ A.class "muted" ] [ text (Translations.searchIntro active.texts) ]
                , div []
                    [ label [ A.for "search-kind" ] [ text (Translations.searchType active.texts) ]
                    , select [ A.id "search-kind", Events.on "change" (Decode.map SearchKindChanged (Decode.at [ "target", "value" ] Decode.string)) ]
                        [ option [ A.value "posts", A.selected (model.search.kind == "posts") ] [ text (Translations.searchPosts active.texts) ]
                        , option [ A.value "communities", A.selected (model.search.kind == "communities") ] [ text (Translations.searchCommunities active.texts) ]
                        ]
                    ]
                , div []
                    [ label [ A.for "search-query" ] [ text (Translations.searchQuery active.texts) ]
                    , input [ A.id "search-query", A.type_ "search", A.required True, A.value model.search.query, Events.onInput SearchQueryChanged ]
                        []
                    ]
                , button [ A.type_ "submit", A.class "filled-button" ] [ text (Translations.searchSubmit active.texts) ]
                ]
            , viewRemote active.texts
                model.search.results
                (\result ->
                    case result of
                        PostSearch page ->
                            if List.isEmpty page.items then
                                emptyWithPagination active.texts model.url page

                            else
                                div [ A.class "stack" ]
                                    [ div [ A.class "stack" ] (List.map (postCard model active) page.items)
                                    , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                                    ]

                        CommunitySearch page ->
                            if List.isEmpty page.items then
                                emptyWithPagination active.texts model.url page

                            else
                                div [ A.class "stack" ]
                                    [ div [ A.class "stack" ] (List.map (communityCard active) page.items)
                                    , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                                    ]
                )
            ]
        )


pageNotifications : Model -> Active -> Html Msg
pageNotifications model active =
    pageHeading (Translations.notificationsTitle active.texts)
        (section [ A.class "primary-column" ]
            [ case model.auth of
                Authenticated _ ->
                    div [ A.class "actions" ]
                        [ button [ A.class "outlined-button", Events.onClick MarkAllNoticesRead ]
                            [ text (Translations.markAllRead active.texts) ]
                        , case model.unreadCount of
                            Just count ->
                                span [ A.class "chip" ] [ text (Translations.unreadNotifications count active.texts) ]

                            Nothing ->
                                text ""
                        ]

                _ ->
                    loginRequired active.texts
            , viewRemote active.texts
                model.notifications
                (\page ->
                    if List.isEmpty page.items then
                        div [ A.class "stack" ]
                            [ p [ A.class "muted" ] [ text (Translations.noNotifications active.texts) ]
                            , viewPagination active.texts model.url page.offset page.limit 0
                            ]

                    else
                        div [ A.class "stack" ]
                            [ ul [ A.class "notification-list" ] (List.map (notificationItem model active) page.items)
                            , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                            ]
                )
            ]
        )


notificationItem : Model -> Active -> Domain.Notice -> Html Msg
notificationItem model active notice =
    li [ A.class "card" ]
        [ p [] [ strong [] [ bdi [] [ text notice.actor ] ], text " ", text (notificationKind active.texts notice.kind) ]
        , p [ A.class "metadata" ] [ time [ A.datetime notice.date, A.attribute "data-commune-time" "" ] [ text (formattedDate model notice.date) ] ]
        , div [ A.class "actions" ]
            [ a [ A.href (Route.path (Route.Post notice.post)) ] [ text (Translations.repliesTitle active.texts) ]
            , if notice.read then
                text ""

              else
                button [ A.class "text-button", Events.onClick (MarkNoticeRead notice.id) ]
                    [ text (Translations.markRead active.texts) ]
            ]
        ]


notificationKind : Translations.I18n -> String -> String
notificationKind texts kind =
    case kind of
        "reply" ->
            Translations.notificationReply texts

        "like" ->
            Translations.notificationLike texts

        "mention" ->
            Translations.notificationMention texts

        _ ->
            Translations.notificationOther texts


pagePublicProfile : Model -> Active -> String -> Html Msg
pagePublicProfile model active username =
    pageHeading (Translations.profileTitle active.texts)
        (viewRemote active.texts model.publicProfile (profileCard active))


profileCard : Active -> Domain.Profile -> Html Msg
profileCard active profile =
    section [ A.class "card profile-card" ]
        [ if String.isEmpty profile.avatar then
            text ""

          else
            img [ A.src profile.avatar, A.alt profile.name, A.class "avatar", A.attribute "referrerpolicy" "no-referrer" ] []
        , h2 []
            [ text
                (if String.isEmpty profile.name then
                    profile.username

                 else
                    profile.name
                )
            ]
        , p [ A.class "metadata" ] [ bdi [] [ text profile.actor ] ]
        , Ui.Rich.view profile.html
        , p [ A.class "muted" ] [ text (Translations.publicProfileNote active.texts) ]
        ]


pageSettings : Model -> Active -> Html Msg
pageSettings model active =
    pageHeading (Translations.settingsTitle active.texts)
        (case model.auth of
            Authenticated _ ->
                form [ Events.onSubmit ProfileSave, A.class "card form-stack" ]
                    [ p [ A.class "muted" ] [ text (Translations.publicProfileNote active.texts) ]
                    , div []
                        [ label [ A.for "profile-name" ] [ text (Translations.displayName active.texts) ]
                        , input [ A.id "profile-name", A.type_ "text", A.attribute "autocomplete" "name", A.value model.profileForm.displayName, Events.onInput ProfileDisplayNameChanged ]
                            []
                        ]
                    , div []
                        [ label [ A.for "profile-bio" ] [ text (Translations.biography active.texts) ]
                        , textarea [ A.id "profile-bio", A.dir "auto", A.value model.profileForm.biography, Events.onInput ProfileBiographyChanged ] []
                        ]
                    , div []
                        [ label [ A.for "profile-avatar" ] [ text (Translations.avatar active.texts) ]
                        , if String.isEmpty model.profileForm.avatarUrl then
                            text ""

                          else
                            img [ A.src model.profileForm.avatarUrl, A.alt "", A.class "avatar", A.attribute "referrerpolicy" "no-referrer" ] []
                        , input
                            [ A.id "profile-avatar"
                            , A.type_ "file"
                            , A.attribute "accept" "image/*"
                            , Events.on "change" (Decode.maybe (Decode.at [ "target", "files", "0" ] File.decoder) |> Decode.map AvatarFileSelected)
                            ]
                            []
                        , button [ A.type_ "button", A.class "text-button", Events.onClick ProfileClearAvatar ]
                            [ text (Translations.removeAvatar active.texts) ]
                        ]
                    , viewFormProblem active.texts model.profileForm.problem
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled (model.profileForm.saving || model.profileForm.uploading) ]
                        [ text (Translations.saveProfile active.texts) ]
                    ]

            _ ->
                loginRequired active.texts
        )


pageNewCommunity : Model -> Active -> Html Msg
pageNewCommunity model active =
    pageHeading (Translations.createCommunity active.texts)
        (case model.auth of
            Authenticated _ ->
                form [ Events.onSubmit CommunityCreate, A.class "card form-stack" ]
                    [ div []
                        [ label [ A.for "community-name" ] [ text (Translations.communityName active.texts) ]
                        , input [ A.id "community-name", A.type_ "text", A.required True, A.value model.createCommunity.name, Events.onInput CommunityNameChanged ]
                            []
                        , p [ A.class "muted" ] [ text (Translations.communityNameHelp active.texts) ]
                        ]
                    , div []
                        [ label [ A.for "community-title" ] [ text (Translations.communityTitle active.texts) ]
                        , input [ A.id "community-title", A.type_ "text", A.required True, A.value model.createCommunity.title, Events.onInput CommunityTitleChanged ]
                            []
                        ]
                    , div []
                        [ label [ A.for "community-mode" ] [ text (Translations.federationMode active.texts) ]
                        , select [ A.id "community-mode", Events.on "change" (Decode.map CommunityModeChanged (Decode.at [ "target", "value" ] Decode.string)) ]
                            [ option [ A.value "federated", A.selected (model.createCommunity.mode == "federated") ] [ text (Translations.federated active.texts) ]
                            , option [ A.value "local_only", A.selected (model.createCommunity.mode == "local_only") ] [ text (Translations.localOnly active.texts) ]
                            ]
                        ]
                    , policyFields active model.createCommunity.readPolicy model.createCommunity.postPolicy CommunityReadChanged CommunityPostChanged
                    , viewFormProblem active.texts model.createCommunity.problem
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled model.createCommunity.busy ]
                        [ text (Translations.create active.texts) ]
                    ]

            _ ->
                loginRequired active.texts
        )


policyFields :
    Active
    -> String
    -> String
    -> (String -> Msg)
    -> (String -> Msg)
    -> Html Msg
policyFields active readPolicy postPolicy onRead onPost =
    div [ A.class "form-grid" ]
        [ div []
            [ label [ A.for "read-policy" ] [ text (Translations.readPolicy active.texts) ]
            , select [ A.id "read-policy", Events.on "change" (Decode.map onRead (Decode.at [ "target", "value" ] Decode.string)) ]
                [ option [ A.value "eligible_users", A.selected (readPolicy == "eligible_users") ] [ text (Translations.eligibleUsers active.texts) ]
                , option [ A.value "members", A.selected (readPolicy == "members") ] [ text (Translations.membersOnly active.texts) ]
                ]
            ]
        , div []
            [ label [ A.for "post-policy" ] [ text (Translations.postPolicy active.texts) ]
            , select [ A.id "post-policy", Events.on "change" (Decode.map onPost (Decode.at [ "target", "value" ] Decode.string)) ]
                [ option [ A.value "eligible_users", A.selected (postPolicy == "eligible_users") ] [ text (Translations.eligibleUsers active.texts) ]
                , option [ A.value "members", A.selected (postPolicy == "members") ] [ text (Translations.membersOnly active.texts) ]
                ]
            ]
        ]


pageManage : Model -> Active -> String -> Html Msg
pageManage model active communityIdValue =
    pageHeading (Translations.manageTitle active.texts)
        (case ( model.auth, model.manage ) of
            ( Authenticated _, Just manage ) ->
                section [ A.class "primary-column" ]
                    [ viewRemote active.texts manage.community (communitySection active)
                    , if canManageCommunity manage then
                        managePolicy active manage

                      else
                        text ""
                    , manageRosters active manage
                    , managePostActions model active manage
                    ]

            _ ->
                loginRequired active.texts
        )


communitySection : Active -> Domain.Community -> Html Msg
communitySection active community =
    section [ A.class "card" ]
        [ h2 [] [ text community.title ]
        , p [ A.class "metadata" ]
            [ text
                (Translations.policySummary
                    { read = policyLabel active.texts community.readPolicy
                    , post = policyLabel active.texts community.postPolicy
                    }
                    active.texts
                )
            ]
        , p [ A.class "chips" ] [ span [ A.class "chip" ] [ text (modeLabel active.texts community.mode) ] ]
        ]


managePolicy : Active -> ManageState -> Html Msg
managePolicy active manage =
    form [ Events.onSubmit ManageApplyPolicy, A.class "card form-stack" ]
        [ h2 [] [ text (Translations.readPolicy active.texts) ]
        , policyFields active manage.readPolicy manage.postPolicy ManageReadChanged ManagePostPolicyChanged
        , button [ A.type_ "submit", A.class "filled-button" ] [ text (Translations.saveChanges active.texts) ]
        ]


manageRosters : Active -> ManageState -> Html Msg
manageRosters active manage =
    let
        canMembers =
            canManageMembers manage

        canManagers =
            canManageManagers manage
    in
    section [ A.class "stack" ]
        [ if canMembers || canManagers then
            div [ A.class "card form-stack" ]
                [ label [ A.for "manage-actor" ] [ text (Translations.actorUri active.texts) ]
                , input [ A.id "manage-actor", A.type_ "text", A.value manage.actor, Events.onInput ManageActorChanged ]
                    []
                , div [ A.class "actions" ]
                    [ if canMembers then
                        button [ A.type_ "button", A.class "outlined-button", Events.onClick ManageAddMember ]
                            [ text (Translations.addMember active.texts) ]

                      else
                        text ""
                    , if canManagers then
                        button [ A.type_ "button", A.class "outlined-button", Events.onClick ManageAddManager ]
                            [ text (Translations.addManager active.texts) ]

                      else
                        text ""
                    ]
                ]

          else
            text ""
        , rosterPanel active (Translations.memberRoster active.texts) manage.members True canMembers manage.memberOffset ManagePreviousMembers ManageNextMembers
        , rosterPanel active (Translations.managerRoster active.texts) manage.managers False canManagers manage.managerOffset ManagePreviousManagers ManageNextManagers
        ]


rosterPanel :
    Active
    -> String
    -> Remote (Domain.Page Domain.Roster)
    -> Bool
    -> Bool
    -> Int
    -> Msg
    -> Msg
    -> Html Msg
rosterPanel active title remote members canRemove offset onPrevious onNext =
    section [ A.class "card" ]
        [ h2 [] [ text title ]
        , viewRemote active.texts
            remote
            (\page ->
                if List.isEmpty page.items then
                    p [ A.class "muted" ] [ text (Translations.noRosterEntries active.texts) ]

                else
                    ul [ A.class "roster-list" ]
                        (List.map
                            (\entry ->
                                li []
                                    [ bdi [] [ text entry.actor ]
                                    , span [ A.class "chips" ]
                                        [ if entry.creator then
                                            span [ A.class "chip" ] [ text (Translations.createCommunity active.texts) ]

                                          else
                                            text ""
                                        , if canRemove && not entry.creator then
                                            button
                                                [ A.type_ "button"
                                                , A.class "text-button danger-text"
                                                , Events.onClick
                                                    (if members then
                                                        ManageRemoveMember entry.actor

                                                     else
                                                        ManageRemoveManager entry.actor
                                                    )
                                                ]
                                                [ text
                                                    (if members then
                                                        Translations.removeMember active.texts

                                                     else
                                                        Translations.removeManager active.texts
                                                    )
                                                ]

                                          else
                                            text ""
                                        ]
                                    ]
                            )
                            page.items
                        )
                        |> (\rows ->
                                div [ A.class "stack" ]
                                    [ rows
                                    , div [ A.class "pagination" ]
                                        [ button [ A.type_ "button", A.class "outlined-button", A.disabled (offset <= 0), Events.onClick onPrevious ]
                                            [ text (Translations.previousPage active.texts) ]
                                        , if List.length page.items >= page.limit then
                                            button [ A.type_ "button", A.class "outlined-button", Events.onClick onNext ]
                                                [ text (Translations.nextPage active.texts) ]

                                          else
                                            text ""
                                        ]
                                    ]
                           )
            )
        ]


managePostActions : Model -> Active -> ManageState -> Html Msg
managePostActions model active manage =
    let
        moderate =
            canManageCommunity manage

        siteAdmin =
            case model.auth of
                Authenticated identity ->
                    identity.siteAdmin || identity.deploymentAdmin

                _ ->
                    False

        canBackfill =
            case manage.community of
                Ready community ->
                    community.canPost

                _ ->
                    False
    in
    section [ A.class "card form-stack" ]
        [ h2 [] [ text (Translations.postId active.texts) ]
        , label [ A.for "manage-post-id" ] [ text (Translations.postId active.texts) ]
        , input [ A.id "manage-post-id", A.type_ "text", A.value manage.postId, Events.onInput ManagePostChanged ] []
        , div [ A.class "actions wrap" ]
            [ if moderate then
                managePostButton active "remove" RemoveCommunityPost manage.postId

              else
                text ""
            , if moderate then
                managePostButton active "restore" RestoreCommunityPost manage.postId

              else
                text ""
            , if siteAdmin then
                managePostButton active "hide" HideSitePost manage.postId

              else
                text ""
            , if siteAdmin then
                managePostButton active "unhide" UnhideSitePost manage.postId

              else
                text ""
            , managePostButton active "import" ImportSitePost manage.postId
            , if moderate then
                managePostButton active "accept" AcceptSubmission manage.postId

              else
                text ""
            , if moderate then
                managePostButton active "reject" RejectSubmission manage.postId

              else
                text ""
            ]
        , if canBackfill then
            div [ A.class "form-stack" ]
                [ label [ A.for "manage-context-id" ] [ text (Translations.contextId active.texts) ]
                , input [ A.id "manage-context-id", A.type_ "text", A.value manage.contextId, Events.onInput ManageContextChanged ] []
                , managePostButton active "backfill" BackfillDiscussion manage.contextId
                ]

          else
            text ""
        , viewFormProblem active.texts manage.problem
        ]


managePostButton : Active -> String -> ManagePostAction -> String -> Html Msg
managePostButton active _ action id =
    button
        [ A.type_ "button"
        , A.class "outlined-button"
        , A.disabled (String.isEmpty (String.trim id))
        , Events.onClick (ManagePostAction id action)
        ]
        [ text (manageActionLabel active.texts action) ]


manageActionLabel : Translations.I18n -> ManagePostAction -> String
manageActionLabel texts action =
    case action of
        RemoveCommunityPost ->
            Translations.removePostFromCommunity texts

        RestoreCommunityPost ->
            Translations.restorePostToCommunity texts

        HideSitePost ->
            Translations.hidePost texts

        UnhideSitePost ->
            Translations.unhidePost texts

        ImportSitePost ->
            Translations.importPost texts

        AcceptSubmission ->
            Translations.acceptSubmission texts

        RejectSubmission ->
            Translations.rejectSubmission texts

        BackfillDiscussion ->
            Translations.backfillContext texts


viewRemote : Translations.I18n -> Remote a -> (a -> Html Msg) -> Html Msg
viewRemote texts remote render =
    case remote of
        NotAsked ->
            text ""

        Loading ->
            p [ A.attribute "role" "status", A.class "loading-state" ] [ text (Translations.loadingMessage texts) ]

        Ready value ->
            render value

        Failed problem ->
            div [ A.class "card field-error", A.attribute "role" "alert" ]
                [ p [] [ text (problemText texts problem) ]
                , button [ A.class "outlined-button", Events.onClick RetryPage ]
                    [ text (Translations.retryLabel texts) ]
                ]


canManageCommunity : ManageState -> Bool
canManageCommunity manage =
    case manage.community of
        Ready community ->
            community.canManage

        _ ->
            False


canManageMembers : ManageState -> Bool
canManageMembers manage =
    case manage.community of
        Ready community ->
            community.canMembers

        _ ->
            False


canManageManagers : ManageState -> Bool
canManageManagers manage =
    case manage.community of
        Ready community ->
            community.canManagers

        _ ->
            False


viewFormProblem : Translations.I18n -> Maybe Api.Problem -> Html Msg
viewFormProblem texts maybeProblem =
    case maybeProblem of
        Just problem ->
            p [ A.class "field-error", A.attribute "role" "alert" ] [ text (problemText texts problem) ]

        Nothing ->
            text ""


viewFormProblemWith : Translations.I18n -> Maybe String -> Html Msg
viewFormProblemWith _ maybeMessage =
    case maybeMessage of
        Just message ->
            p [ A.class "field-error", A.attribute "role" "alert" ] [ text message ]

        Nothing ->
            text ""


viewFormProblemWithId : Translations.I18n -> String -> Maybe String -> Html Msg
viewFormProblemWithId _ identifier maybeMessage =
    case maybeMessage of
        Just message ->
            p [ A.id identifier, A.class "field-error", A.attribute "role" "alert" ] [ text message ]

        Nothing ->
            text ""


problemText : Translations.I18n -> Api.Problem -> String
problemText texts problem =
    case problem.status of
        0 ->
            Translations.connectionError texts

        400 ->
            Translations.invalidInput texts

        401 ->
            Translations.sessionExpired texts

        403 ->
            Translations.forbidden texts

        404 ->
            Translations.notFound texts

        409 ->
            if String.contains "edit_conflict" problem.detail then
                Translations.editConflict texts

            else
                Translations.conflict texts

        429 ->
            Translations.rateLimited texts

        503 ->
            Translations.unavailable texts

        _ ->
            Translations.requestFailed texts


emptyState : Translations.I18n -> Html Msg
emptyState texts =
    p [ A.class "empty-state" ] [ text (Translations.emptyLatest texts) ]


emptyWithPagination : Translations.I18n -> Url -> Domain.Page a -> Html Msg
emptyWithPagination texts url page =
    div [ A.class "stack" ]
        [ emptyState texts
        , viewPagination texts url page.offset page.limit 0
        ]


loginRequired : Translations.I18n -> Html Msg
loginRequired texts =
    div [ A.class "card" ]
        [ p [] [ text (Translations.loginRequired texts) ]
        , a [ A.class "filled-button", A.href (Route.path Route.Login) ] [ text (Translations.loginSubmit texts) ]
        ]


viewPagination : Translations.I18n -> Url -> Int -> Int -> Int -> Html Msg
viewPagination texts url offset limit count =
    div [ A.class "pagination" ]
        [ if offset > 0 then
            a [ A.class "outlined-button", A.href (Route.pageUrl url (max 0 (offset - limit))) ]
                [ text (Translations.previousPage texts) ]

          else
            text ""
        , if count >= limit then
            a [ A.class "outlined-button", A.href (Route.pageUrl url (offset + limit)) ]
                [ text (Translations.nextPage texts) ]

          else
            text ""
        ]


languageSelect : String -> (String -> Msg) -> Locale -> Html Msg
languageSelect identifier tagger selected =
    select
        [ A.id identifier
        , A.value (Locale.code selected)
        , Events.on "change" (Decode.map tagger (Decode.at [ "target", "value" ] Decode.string))
        ]
        (List.map
            (\locale ->
                option [ A.value (Locale.code locale), A.selected (locale == selected) ]
                    [ text (Locale.label locale) ]
            )
            Locale.all
        )


pendingIndicator : Model -> Active -> Html Msg
pendingIndicator model active =
    case Localization.pending model.loading of
        Just _ ->
            span [ A.class "pending-label", A.attribute "role" "status" ]
                [ text (Translations.loadingMessage active.texts) ]

        Nothing ->
            text ""


formattedDate : Model -> String -> String
formattedDate model source =
    case model.formatted of
        Just current ->
            if current.source == source then
                current.absolute

            else
                source

        Nothing ->
            source


likesLabel : Model -> Translations.I18n -> Int -> String
likesLabel model texts count =
    if pluralCategory model count == "one" then
        Translations.likesOne (formattedCount model count) texts

    else
        Translations.likesOther (formattedCount model count) texts


repliesLabel : Model -> Translations.I18n -> Int -> String
repliesLabel model texts count =
    if pluralCategory model count == "one" then
        Translations.repliesOne (formattedCount model count) texts

    else
        Translations.repliesOther (formattedCount model count) texts


formattedCount : Model -> Int -> String
formattedCount model count =
    case model.formatted of
        Just current ->
            current.numbers
                |> List.filter (\( source, _ ) -> source == count)
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.withDefault (String.fromInt count)

        Nothing ->
            String.fromInt count


pluralCategory : Model -> Int -> String
pluralCategory model count =
    case model.formatted of
        Just current ->
            current.plurals
                |> List.filter (\( source, _ ) -> source == count)
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.withDefault "other"

        Nothing ->
            "other"


boolText : Bool -> String
boolText value =
    if value then
        "true"

    else
        "false"


policyLabel : Translations.I18n -> String -> String
policyLabel texts policy =
    if policy == "members" then
        Translations.membersOnly texts

    else
        Translations.eligibleUsers texts


modeLabel : Translations.I18n -> String -> String
modeLabel texts mode =
    if mode == "local_only" then
        Translations.localOnly texts

    else
        Translations.federated texts


signedInLabel : Translations.I18n -> Domain.Identity -> String
signedInLabel texts identity =
    Translations.signedInAs identity.username texts
        ++ (if identity.siteAdmin then
                " · " ++ Translations.siteAdministrator texts

            else
                ""
           )
        ++ (if identity.deploymentAdmin then
                " · " ++ Translations.deploymentAdministrator texts

            else
                ""
           )


subscriptions : Model -> Sub Msg
subscriptions _ =
    incoming Incoming


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

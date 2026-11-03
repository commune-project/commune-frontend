module Feature.Profile exposing (Action(..), AvatarChange(..), Config, Model, Msg(..), Outcome, ProfileForm, clearPrivate, emptyProfileForm, initial, loadOwn, loadPublic, pagePublicProfile, pageSettings, profileCard, profileFormFrom, reset, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Domain
import Feature.Authoring.State as AuthoringState
import Feature.Authoring.Update as Authoring
import Feature.Authoring.View as AuthoringView
import File exposing (File)
import Generated.I18n as Translations
import Html exposing (Html, a, bdi, button, div, form, h2, img, input, label, p, section, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Remote exposing (Remote(..))
import Route
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Layout exposing (entityHeading, pageHeading)
import Ui.Rich
import Url


type AvatarChange
    = KeepAvatar
    | ClearAvatar
    | ReplaceAvatar String


type alias ProfileForm =
    { displayName : String
    , authoring : AuthoringState.Model
    , avatar : AvatarChange
    , avatarUrl : String
    , uploading : Bool
    , saving : Bool
    , problem : Maybe Api.Problem
    }


emptyProfileForm : ProfileForm
emptyProfileForm =
    { displayName = "", authoring = AuthoringState.init "profile-bio" "", avatar = KeepAvatar, avatarUrl = "", uploading = False, saving = False, problem = Nothing }


profileFormFrom : Domain.Profile -> ProfileForm
profileFormFrom profile =
    { displayName = profile.name
    , authoring = AuthoringState.init "profile-bio" profile.biography
    , avatar = KeepAvatar
    , avatarUrl = profile.avatar
    , uploading = False
    , saving = False
    , problem = Nothing
    }


type alias Model =
    { publicProfile : Remote Domain.Profile, ownProfile : Remote Domain.Profile, profileForm : ProfileForm }


initial : Model
initial =
    { publicProfile = NotAsked, ownProfile = NotAsked, profileForm = emptyProfileForm }


type Msg
    = ActionDone Action Api.Response
    | PublicLoaded Api.Response
    | OwnLoaded Api.Response
    | ProfileDisplayNameChanged String
    | ProfileAuthoring Authoring.Msg
    | ProfileClearAvatar
    | ProfileSave
    | AvatarFileSelected (Maybe File)


type Action
    = ProfileSaveAction
    | UploadAvatarAction


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem }


type alias Working =
    { publicProfile : Remote Domain.Profile, ownProfile : Remote Domain.Profile, profileForm : ProfileForm, flash : Flash, sessionProblem : Maybe Api.Problem }


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message state =
    let
        ( next, command ) =
            updateWorking csrf message { publicProfile = state.publicProfile, ownProfile = state.ownProfile, profileForm = state.profileForm, flash = NoFlash, sessionProblem = Nothing }
    in
    ( { publicProfile = next.publicProfile, ownProfile = next.ownProfile, profileForm = next.profileForm }, command, { flash = next.flash, sessionProblem = next.sessionProblem } )


updateWorking : String -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf message model =
    case message of
        ProfileDisplayNameChanged value ->
            ( { model | profileForm = (\form -> { form | displayName = value, problem = Nothing }) model.profileForm }, Cmd.none )

        ProfileAuthoring authoringMessage ->
            let
                ( authoring, command, outcome ) =
                    Authoring.update authoringMessage model.profileForm.authoring
            in
            ( { model
                | profileForm =
                    (\form ->
                        { form
                            | authoring = authoring
                            , problem =
                                if outcome.changed then
                                    Nothing

                                else
                                    form.problem
                        }
                    )
                        model.profileForm
              }
            , Cmd.map ProfileAuthoring command
            )

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
            , Api.send csrf
                "PATCH"
                "/api/v1/profile"
                (Encode.encode 0
                    (Encode.object
                        ([ ( "display_name", Encode.string model.profileForm.displayName )
                         , ( "biography", Encode.string (AuthoringState.value model.profileForm.authoring) )
                         ]
                            ++ avatar
                        )
                    )
                )
                (ActionDone ProfileSaveAction)
            )

        AvatarFileSelected maybeFile ->
            case maybeFile of
                Just file ->
                    ( { model | profileForm = (\form -> { form | uploading = True, problem = Nothing }) model.profileForm }
                    , Api.upload csrf "avatar" file (ActionDone UploadAvatarAction)
                    )

                Nothing ->
                    ( model, Cmd.none )

        ActionDone action response ->
            case action of
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

        PublicLoaded response ->
            case Api.decodeResponse Domain.profile response of
                Ok profile ->
                    ( { model | publicProfile = Ready profile }, Cmd.none )

                Err problem ->
                    ( { model
                        | publicProfile = Failed problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )

        OwnLoaded response ->
            case Api.decodeResponse Domain.profile response of
                Ok profile ->
                    ( { model | ownProfile = Ready profile, profileForm = profileFormFrom profile }, Cmd.none )

                Err problem ->
                    ( { model
                        | ownProfile = Failed problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )


type alias Config msg =
    { retry : msg
    , profileDisplayNameChanged : String -> msg
    , profileAuthoring : Authoring.Msg -> msg
    , profileClearAvatar : msg
    , profileSave : msg
    , avatarFileSelected : Maybe File -> msg
    , reportPerson : String -> msg
    }


type alias ViewModel =
    { publicProfile : Remote Domain.Profile
    , ownProfile : Remote Domain.Profile
    , profileForm : ProfileForm
    , auth : AuthState
    }


pagePublicProfile : Config msg -> ViewModel -> Active -> String -> Html msg
pagePublicProfile config model active username =
    entityHeading (Translations.profileTitle active.texts)
        (viewRemote config.retry
            active.texts
            model.publicProfile
            (\profile ->
                div [ A.class "stack" ]
                    [ profileCard active profile
                    , case model.auth of
                        Authenticated _ ->
                            button
                                [ A.type_ "button"
                                , A.class "outlined-button"
                                , Events.onClick (config.reportPerson profile.actor)
                                ]
                                [ text (Translations.reportPerson active.texts) ]

                        _ ->
                            text ""
                    ]
            )
        )


profileCard : Active -> Domain.Profile -> Html msg
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


pageSettings : Config msg -> ViewModel -> Active -> Html msg
pageSettings config model active =
    pageHeading (Translations.settingsTitle active.texts)
        (case model.auth of
            Authenticated _ ->
                form [ Events.onSubmit config.profileSave, A.class "card form-stack" ]
                    [ p [ A.class "muted" ] [ text (Translations.publicProfileNote active.texts) ]
                    , div []
                        [ label [ A.for "profile-name" ] [ text (Translations.displayName active.texts) ]
                        , input [ A.id "profile-name", A.type_ "text", A.attribute "autocomplete" "name", A.value model.profileForm.displayName, Events.onInput config.profileDisplayNameChanged ]
                            []
                        ]
                    , AuthoringView.view
                        { id = "profile-bio"
                        , label = Translations.biography active.texts
                        , helpId = "profile-bio-help"
                        , helpText = Translations.biographyHelp active.texts
                        , required = False
                        , toMsg = config.profileAuthoring
                        }
                        active
                        model.profileForm.authoring
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
                            , Events.on "change" (Decode.maybe (Decode.at [ "target", "files", "0" ] File.decoder) |> Decode.map config.avatarFileSelected)
                            ]
                            []
                        , button [ A.type_ "button", A.class "text-button", Events.onClick config.profileClearAvatar ]
                            [ text (Translations.removeAvatar active.texts) ]
                        ]
                    , viewFormProblem active.texts model.profileForm.problem
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled (model.profileForm.saving || model.profileForm.uploading) ]
                        [ text (Translations.saveProfile active.texts) ]
                    , a [ A.href (Route.path Route.PasswordSettings) ] [ text (Translations.changePasswordTitle active.texts) ]
                    ]

            _ ->
                loginRequired active.texts
        )


reset : Model -> Model
reset model =
    { model | publicProfile = NotAsked, ownProfile = NotAsked }


clearPrivate : Model -> Model
clearPrivate model =
    { model | ownProfile = NotAsked, profileForm = emptyProfileForm }


loadPublic : String -> Model -> ( Model, Cmd Msg )
loadPublic username model =
    ( { model | publicProfile = Loading }
    , Api.get ("/api/v1/profiles/" ++ Url.percentEncode username) PublicLoaded
    )


loadOwn : Model -> ( Model, Cmd Msg )
loadOwn model =
    ( { model | ownProfile = Loading }, Api.get "/api/v1/profile" OwnLoaded )

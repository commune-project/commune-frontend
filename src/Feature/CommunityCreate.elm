module Feature.CommunityCreate exposing (CommunityForm, Config, Model, Msg(..), Outcome, emptyCommunityForm, initial, normalizePolicies, pageNewCommunity, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Domain
import Generated.I18n as Translations
import Html exposing (Html, button, div, form, input, label, option, p, select, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Route
import Ui.CommunityPolicy exposing (policyFields)
import Ui.Feedback exposing (loginRequired, viewFormProblem)
import Ui.Layout exposing (pageHeading)


type alias CommunityForm =
    { name : String
    , title : String
    , mode : String
    , readPolicy : String
    , postPolicy : String
    , busy : Bool
    , problem : Maybe Api.Problem
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


type alias Model =
    { createCommunity : CommunityForm }


initial : Model
initial =
    { createCommunity = emptyCommunityForm }


type Msg
    = Created Api.Response
    | CommunityNameChanged String
    | CommunityTitleChanged String
    | CommunityModeChanged String
    | CommunityReadChanged String
    | CommunityPostChanged String
    | CommunityCreate


type alias Outcome =
    { flash : Flash, navigation : Maybe String }


type alias Working =
    { createCommunity : CommunityForm, flash : Flash, navigation : Maybe String }


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message state =
    let
        ( next, command ) =
            updateWorking csrf message { createCommunity = state.createCommunity, flash = NoFlash, navigation = Nothing }
    in
    ( { createCommunity = next.createCommunity }, command, { flash = next.flash, navigation = next.navigation } )


updateWorking : String -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf message model =
    case message of
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
                , Api.send csrf
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
                    Created
                )

        Created response ->
            case Api.decodeResponse Domain.community response of
                Ok community ->
                    ( { model | createCommunity = emptyCommunityForm, flash = FlashCreated, navigation = Just (Route.path (Route.Community community.id)) }, Cmd.none )

                Err problem ->
                    ( { model | createCommunity = (\form -> { form | busy = False, problem = Just problem }) model.createCommunity }, Cmd.none )


type alias Config msg =
    { retry : msg
    , communityNameChanged : String -> msg
    , communityTitleChanged : String -> msg
    , communityModeChanged : String -> msg
    , communityReadChanged : String -> msg
    , communityPostChanged : String -> msg
    , communityCreate : msg
    }


type alias ViewModel =
    { createCommunity : CommunityForm
    , auth : AuthState
    }


pageNewCommunity : Config msg -> ViewModel -> Active -> Html msg
pageNewCommunity config model active =
    pageHeading (Translations.createCommunity active.texts)
        (case model.auth of
            Authenticated _ ->
                form [ Events.onSubmit config.communityCreate, A.class "card form-stack" ]
                    [ div []
                        [ label [ A.for "community-name" ] [ text (Translations.communityName active.texts) ]
                        , input [ A.id "community-name", A.type_ "text", A.required True, A.value model.createCommunity.name, Events.onInput config.communityNameChanged ]
                            []
                        , p [ A.class "muted" ] [ text (Translations.communityNameHelp active.texts) ]
                        ]
                    , div []
                        [ label [ A.for "community-title" ] [ text (Translations.communityTitle active.texts) ]
                        , input [ A.id "community-title", A.type_ "text", A.required True, A.value model.createCommunity.title, Events.onInput config.communityTitleChanged ]
                            []
                        ]
                    , div []
                        [ label [ A.for "community-mode" ] [ text (Translations.federationMode active.texts) ]
                        , select [ A.id "community-mode", Events.on "change" (Decode.map config.communityModeChanged (Decode.at [ "target", "value" ] Decode.string)) ]
                            [ option [ A.value "federated", A.selected (model.createCommunity.mode == "federated") ] [ text (Translations.federated active.texts) ]
                            , option [ A.value "local_only", A.selected (model.createCommunity.mode == "local_only") ] [ text (Translations.localOnly active.texts) ]
                            ]
                        ]
                    , policyFields active model.createCommunity.readPolicy model.createCommunity.postPolicy config.communityReadChanged config.communityPostChanged
                    , viewFormProblem active.texts model.createCommunity.problem
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled model.createCommunity.busy ]
                        [ text (Translations.create active.texts) ]
                    ]

            _ ->
                loginRequired active.texts
        )

module Feature.Auth.Update exposing (Action(..), Msg(..), Outcome, isSessionAction, update)

import Api
import App.Feedback exposing (Flash(..))
import Domain
import Feature.Auth.State exposing (Model)
import Json.Encode as Encode


type Msg
    = ActionDone Action Api.Response
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


type Action
    = LoginAction
    | LogoutAction
    | RegisterAction
    | ResendAction
    | VerifyAction


type alias Outcome =
    { flash : Flash
    , identity : Maybe Domain.Identity
    , loggedOut : Bool
    }


type alias Working =
    { verificationToken : String
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
    , flash : Flash
    , identity : Maybe Domain.Identity
    , loggedOut : Bool
    }


isSessionAction : Msg -> Bool
isSessionAction msg =
    case msg of
        ActionDone LoginAction _ ->
            True

        ActionDone LogoutAction _ ->
            True

        _ ->
            False


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message state =
    let
        ( next, command ) =
            updateWorking csrf
                message
                { verificationToken = state.verificationToken
                , loginIdentifier = state.loginIdentifier
                , loginPassword = state.loginPassword
                , loginProblem = state.loginProblem
                , loginBusy = state.loginBusy
                , registerUsername = state.registerUsername
                , registerEmail = state.registerEmail
                , registerProblem = state.registerProblem
                , registerBusy = state.registerBusy
                , verifyPassword = state.verifyPassword
                , verifyProblem = state.verifyProblem
                , verifyBusy = state.verifyBusy
                , verified = state.verified
                , flash = NoFlash
                , identity = Nothing
                , loggedOut = False
                }
    in
    ( { verificationToken = next.verificationToken, loginIdentifier = next.loginIdentifier, loginPassword = next.loginPassword, loginProblem = next.loginProblem, loginBusy = next.loginBusy, registerUsername = next.registerUsername, registerEmail = next.registerEmail, registerProblem = next.registerProblem, registerBusy = next.registerBusy, verifyPassword = next.verifyPassword, verifyProblem = next.verifyProblem, verifyBusy = next.verifyBusy, verified = next.verified }
    , command
    , { flash = next.flash, identity = next.identity, loggedOut = next.loggedOut }
    )


updateWorking : String -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf message model =
    case message of
        LoginIdentifierChanged value ->
            ( { model | loginIdentifier = value, loginProblem = Nothing }, Cmd.none )

        LoginPasswordChanged value ->
            ( { model | loginPassword = value, loginProblem = Nothing }, Cmd.none )

        LoginSubmitted ->
            if model.loginBusy then
                ( model, Cmd.none )

            else
                ( { model | loginBusy = True, loginProblem = Nothing }
                , Api.send csrf
                    "POST"
                    "/api/v1/auth/login"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "login", Encode.string model.loginIdentifier )
                            , ( "password", Encode.string model.loginPassword )
                            ]
                        )
                    )
                    (ActionDone LoginAction)
                )

        Logout ->
            ( model, Api.send csrf "POST" "/api/v1/auth/logout" "" (ActionDone LogoutAction) )

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
                    (ActionDone RegisterAction)
                )

        ResendSubmitted ->
            ( model
            , Api.send ""
                "POST"
                "/api/v1/auth/verification/resend"
                (Encode.encode 0 (Encode.object [ ( "email", Encode.string model.registerEmail ) ]))
                (ActionDone ResendAction)
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
                    (ActionDone VerifyAction)
                )

        ActionDone action response ->
            case action of
                LoginAction ->
                    case Api.decodeResponse Domain.identity response of
                        Ok identity ->
                            ( { model | identity = Just identity, loginBusy = False, loginPassword = "", loginProblem = Nothing }, Cmd.none )

                        Err problem ->
                            ( { model | loginBusy = False, loginProblem = Just problem }, Cmd.none )

                LogoutAction ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( { model | loggedOut = True, flash = FlashLoggedOut }, Cmd.none )

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

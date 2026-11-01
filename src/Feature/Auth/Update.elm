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
    | ResetEmailChanged String
    | ResetRequested
    | ResetNewPasswordChanged String
    | ResetSubmitted
    | ChangeCurrentPasswordChanged String
    | ChangeNewPasswordChanged String
    | ChangePasswordSubmitted


type Action
    = LoginAction
    | LogoutAction
    | RegisterAction
    | ResendAction
    | VerifyAction
    | ResetRequestAction
    | ResetConfirmAction
    | ChangePasswordAction


type alias Outcome =
    { flash : Flash
    , identity : Maybe Domain.Identity
    , loggedOut : Bool
    , navigation : Maybe String
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
    , resetEmail : String
    , resetProblem : Maybe Api.Problem
    , resetAccepted : Bool
    , resetToken : String
    , resetNewPassword : String
    , resetBusy : Bool
    , resetComplete : Bool
    , changeCurrentPassword : String
    , changeNewPassword : String
    , changeProblem : Maybe Api.Problem
    , changeBusy : Bool
    , flash : Flash
    , identity : Maybe Domain.Identity
    , loggedOut : Bool
    , navigation : Maybe String
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
                , resetEmail = state.resetEmail
                , resetProblem = state.resetProblem
                , resetAccepted = state.resetAccepted
                , resetToken = state.resetToken
                , resetNewPassword = state.resetNewPassword
                , resetBusy = state.resetBusy
                , resetComplete = state.resetComplete
                , changeCurrentPassword = state.changeCurrentPassword
                , changeNewPassword = state.changeNewPassword
                , changeProblem = state.changeProblem
                , changeBusy = state.changeBusy
                , flash = NoFlash
                , identity = Nothing
                , loggedOut = False
                , navigation = Nothing
                }
    in
    ( { verificationToken = next.verificationToken
      , loginIdentifier = next.loginIdentifier
      , loginPassword = next.loginPassword
      , loginProblem = next.loginProblem
      , loginBusy = next.loginBusy
      , registerUsername = next.registerUsername
      , registerEmail = next.registerEmail
      , registerProblem = next.registerProblem
      , registerBusy = next.registerBusy
      , verifyPassword = next.verifyPassword
      , verifyProblem = next.verifyProblem
      , verifyBusy = next.verifyBusy
      , verified = next.verified
      , resetEmail = next.resetEmail
      , resetProblem = next.resetProblem
      , resetAccepted = next.resetAccepted
      , resetToken = next.resetToken
      , resetNewPassword = next.resetNewPassword
      , resetBusy = next.resetBusy
      , resetComplete = next.resetComplete
      , changeCurrentPassword = next.changeCurrentPassword
      , changeNewPassword = next.changeNewPassword
      , changeProblem = next.changeProblem
      , changeBusy = next.changeBusy
      }
    , command
    , { flash = next.flash, identity = next.identity, loggedOut = next.loggedOut, navigation = next.navigation }
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

        ResetEmailChanged value ->
            ( { model | resetEmail = value, resetProblem = Nothing, resetAccepted = False }, Cmd.none )

        ResetRequested ->
            if model.resetBusy || String.isEmpty (String.trim model.resetEmail) then
                ( model, Cmd.none )

            else
                ( { model | resetBusy = True, resetProblem = Nothing, resetAccepted = False }
                , Api.send ""
                    "POST"
                    "/api/v1/auth/password/reset"
                    (Encode.encode 0 (Encode.object [ ( "email", Encode.string (String.trim model.resetEmail) ) ]))
                    (ActionDone ResetRequestAction)
                )

        ResetNewPasswordChanged value ->
            ( { model | resetNewPassword = value, resetProblem = Nothing }, Cmd.none )

        ResetSubmitted ->
            if model.resetBusy || String.isEmpty model.resetToken then
                ( model, Cmd.none )

            else
                ( { model | resetBusy = True, resetProblem = Nothing }
                , Api.send ""
                    "POST"
                    "/api/v1/auth/password/reset/confirm"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "token", Encode.string model.resetToken )
                            , ( "password", Encode.string model.resetNewPassword )
                            ]
                        )
                    )
                    (ActionDone ResetConfirmAction)
                )

        ChangeCurrentPasswordChanged value ->
            ( { model | changeCurrentPassword = value, changeProblem = Nothing }, Cmd.none )

        ChangeNewPasswordChanged value ->
            ( { model | changeNewPassword = value, changeProblem = Nothing }, Cmd.none )

        ChangePasswordSubmitted ->
            if model.changeBusy then
                ( model, Cmd.none )

            else
                ( { model | changeBusy = True, changeProblem = Nothing }
                , Api.send csrf
                    "POST"
                    "/api/v1/auth/password/change"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "current_password", Encode.string model.changeCurrentPassword )
                            , ( "new_password", Encode.string model.changeNewPassword )
                            ]
                        )
                    )
                    (ActionDone ChangePasswordAction)
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

                ResetRequestAction ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( { model | resetBusy = False, resetAccepted = True, resetProblem = Nothing, flash = FlashResetRequested }, Cmd.none )

                        Err problem ->
                            ( { model | resetBusy = False, resetProblem = Just problem, flash = FlashProblem problem }, Cmd.none )

                ResetConfirmAction ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( { model
                                | resetBusy = False
                                , resetToken = ""
                                , resetNewPassword = ""
                                , resetComplete = True
                                , resetProblem = Nothing
                                , navigation = Just "/login"
                              }
                            , Cmd.none
                            )

                        Err problem ->
                            ( { model | resetBusy = False, resetProblem = Just problem, flash = FlashProblem problem }, Cmd.none )

                ChangePasswordAction ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( { model
                                | changeBusy = False
                                , changeCurrentPassword = ""
                                , changeNewPassword = ""
                                , changeProblem = Nothing
                                , flash = FlashPasswordChanged
                              }
                            , Cmd.none
                            )

                        Err problem ->
                            ( { model | changeBusy = False, changeProblem = Just problem, flash = FlashProblem problem }, Cmd.none )

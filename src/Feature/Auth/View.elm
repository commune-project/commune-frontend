module Feature.Auth.View exposing (Config, pageLogin, pagePasswordReset, pagePasswordResetConfirm, pagePasswordSettings, pageRegister, pageVerify)

import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Feature.Auth.State exposing (Model)
import Generated.I18n as Translations
import Html exposing (Html, a, button, div, form, input, label, p, section, text)
import Html.Attributes as A
import Html.Events as Events
import Route
import Ui.Feedback exposing (loginRequired, problemText, viewFormProblemWithId)
import Ui.Formatting exposing (boolText)
import Ui.Layout exposing (pageHeading)


type alias Config msg =
    { retry : msg
    , loginIdentifierChanged : String -> msg
    , loginPasswordChanged : String -> msg
    , loginSubmitted : msg
    , logout : msg
    , registerUsernameChanged : String -> msg
    , registerEmailChanged : String -> msg
    , registerSubmitted : msg
    , resendSubmitted : msg
    , verifyPasswordChanged : String -> msg
    , verifySubmitted : msg
    , resetEmailChanged : String -> msg
    , resetRequested : msg
    , resetNewPasswordChanged : String -> msg
    , resetSubmitted : msg
    , changeCurrentPasswordChanged : String -> msg
    , changeNewPasswordChanged : String -> msg
    , changePasswordSubmitted : msg
    }


pageLogin : Config msg -> AuthState -> Model -> Active -> Html msg
pageLogin config auth model active =
    pageHeading (Translations.loginTitle active.texts)
        (section [ A.class "primary-column" ]
            [ case auth of
                Authenticated identity ->
                    p [] [ text (Translations.signedInAs identity.username active.texts) ]

                _ ->
                    form [ Events.onSubmit config.loginSubmitted, A.class "card form-stack" ]
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
                                , Events.onInput config.loginIdentifierChanged
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
                                , Events.onInput config.loginPasswordChanged
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
                            , text " · "
                            , a [ A.href (Route.path Route.PasswordReset) ] [ text (Translations.resetPasswordTitle active.texts) ]
                            ]
                        ]
            ]
        )


pageRegister : Config msg -> AuthState -> Model -> Active -> Html msg
pageRegister config auth model active =
    pageHeading (Translations.registerTitle active.texts)
        (form [ Events.onSubmit config.registerSubmitted, A.class "card form-stack" ]
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
                    , Events.onInput config.registerUsernameChanged
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
                    , Events.onInput config.registerEmailChanged
                    ]
                    []
                ]
            , viewFormProblemWithId active.texts "register-error" (Maybe.map (problemText active.texts) model.registerProblem)
            , button [ A.type_ "submit", A.class "filled-button", A.disabled model.registerBusy ]
                [ text (Translations.registerSubmit active.texts) ]
            , button [ A.type_ "button", A.class "text-button", Events.onClick config.resendSubmitted ]
                [ text (Translations.resendVerification active.texts) ]
            ]
        )


pageVerify : Config msg -> AuthState -> Model -> Active -> Html msg
pageVerify config auth model active =
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
                form [ Events.onSubmit config.verifySubmitted, A.class "form-stack" ]
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
                            , Events.onInput config.verifyPasswordChanged
                            ]
                            []
                        ]
                    , viewFormProblemWithId active.texts "verify-error" (Maybe.map (problemText active.texts) model.verifyProblem)
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled model.verifyBusy ]
                        [ text (Translations.verifySubmit active.texts) ]
                    ]
            ]
        )


pagePasswordReset : Config msg -> AuthState -> Model -> Active -> Html msg
pagePasswordReset config _ model active =
    pageHeading (Translations.resetPasswordTitle active.texts)
        (form [ Events.onSubmit config.resetRequested, A.class "card form-stack" ]
            [ p [ A.class "muted" ] [ text (Translations.resetPasswordHelp active.texts) ]
            , div []
                [ label [ A.for "reset-email" ] [ text (Translations.email active.texts) ]
                , input
                    [ A.id "reset-email"
                    , A.type_ "email"
                    , A.attribute "autocomplete" "email"
                    , A.required True
                    , A.value model.resetEmail
                    , Events.onInput config.resetEmailChanged
                    ]
                    []
                ]
            , viewFormProblemWithId active.texts "reset-error" (Maybe.map (problemText active.texts) model.resetProblem)
            , button [ A.type_ "submit", A.class "filled-button", A.disabled model.resetBusy ]
                [ text (Translations.requestReset active.texts) ]
            ]
        )


pagePasswordResetConfirm : Config msg -> AuthState -> Model -> Active -> Html msg
pagePasswordResetConfirm config _ model active =
    pageHeading (Translations.resetPasswordTitle active.texts)
        (section [ A.class "card form-stack" ]
            [ if model.resetComplete then
                div [ A.class "notice", A.attribute "role" "status" ]
                    [ p [] [ text (Translations.resetSuccess active.texts) ]
                    , a [ A.href (Route.path Route.Login) ] [ text (Translations.loginSubmit active.texts) ]
                    ]

              else if String.isEmpty model.resetToken then
                p [ A.class "field-error", A.attribute "role" "alert" ] [ text (Translations.verificationMissing active.texts) ]

              else
                form [ Events.onSubmit config.resetSubmitted, A.class "form-stack" ]
                    [ div []
                        [ label [ A.for "reset-new-password" ] [ text (Translations.newPassword active.texts) ]
                        , input
                            [ A.id "reset-new-password"
                            , A.type_ "password"
                            , A.attribute "autocomplete" "new-password"
                            , A.required True
                            , A.value model.resetNewPassword
                            , Events.onInput config.resetNewPasswordChanged
                            ]
                            []
                        ]
                    , viewFormProblemWithId active.texts "reset-confirm-error" (Maybe.map (problemText active.texts) model.resetProblem)
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled model.resetBusy ]
                        [ text (Translations.confirmReset active.texts) ]
                    ]
            ]
        )


pagePasswordSettings : Config msg -> AuthState -> Model -> Active -> Html msg
pagePasswordSettings config auth model active =
    pageHeading (Translations.changePasswordTitle active.texts)
        (case auth of
            Authenticated _ ->
                form [ Events.onSubmit config.changePasswordSubmitted, A.class "card form-stack" ]
                    [ div []
                        [ label [ A.for "change-current-password" ] [ text (Translations.currentPassword active.texts) ]
                        , input
                            [ A.id "change-current-password"
                            , A.type_ "password"
                            , A.attribute "autocomplete" "current-password"
                            , A.required True
                            , A.value model.changeCurrentPassword
                            , Events.onInput config.changeCurrentPasswordChanged
                            ]
                            []
                        ]
                    , div []
                        [ label [ A.for "change-new-password" ] [ text (Translations.newPassword active.texts) ]
                        , input
                            [ A.id "change-new-password"
                            , A.type_ "password"
                            , A.attribute "autocomplete" "new-password"
                            , A.required True
                            , A.value model.changeNewPassword
                            , Events.onInput config.changeNewPasswordChanged
                            ]
                            []
                        ]
                    , viewFormProblemWithId active.texts "change-password-error" (Maybe.map (problemText active.texts) model.changeProblem)
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled model.changeBusy ]
                        [ text (Translations.changePassword active.texts) ]
                    ]

            _ ->
                loginRequired active.texts
        )

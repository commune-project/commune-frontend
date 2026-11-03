module App.View.Account exposing (pageLogin, pagePasswordReset, pagePasswordResetConfirm, pagePasswordSettings, pagePublicProfile, pageRegister, pageSettings, pageVerify)

import App.Context exposing (Active)
import App.State exposing (Model, Msg(..))
import Feature.Auth.Update as Auth
import Feature.Auth.View
import Feature.Profile as Profile
import Feature.Report as Report
import Html exposing (Html)


pageLogin : Model -> Active -> Html Msg
pageLogin model active =
    Feature.Auth.View.pageLogin (authViewConfig model) model.auth model.account active


pageRegister : Model -> Active -> Html Msg
pageRegister model active =
    Feature.Auth.View.pageRegister (authViewConfig model) model.auth model.account active


pageVerify : Model -> Active -> Html Msg
pageVerify model active =
    Feature.Auth.View.pageVerify (authViewConfig model) model.auth model.account active


pagePasswordReset : Model -> Active -> Html Msg
pagePasswordReset model active =
    Feature.Auth.View.pagePasswordReset (authViewConfig model) model.auth model.account active


pagePasswordResetConfirm : Model -> Active -> Html Msg
pagePasswordResetConfirm model active =
    Feature.Auth.View.pagePasswordResetConfirm (authViewConfig model) model.auth model.account active


pagePasswordSettings : Model -> Active -> Html Msg
pagePasswordSettings model active =
    Feature.Auth.View.pagePasswordSettings (authViewConfig model) model.auth model.account active


authViewConfig : Model -> Feature.Auth.View.Config Msg
authViewConfig model =
    { retry = RetryPage
    , loginIdentifierChanged = AuthMessage << Auth.LoginIdentifierChanged
    , loginPasswordChanged = AuthMessage << Auth.LoginPasswordChanged
    , loginSubmitted = AuthMessage Auth.LoginSubmitted
    , logout = AuthMessage Auth.Logout
    , registerUsernameChanged = AuthMessage << Auth.RegisterUsernameChanged
    , registerEmailChanged = AuthMessage << Auth.RegisterEmailChanged
    , registerSubmitted = AuthMessage Auth.RegisterSubmitted
    , resendSubmitted = AuthMessage Auth.ResendSubmitted
    , verifyPasswordChanged = AuthMessage << Auth.VerifyPasswordChanged
    , verifySubmitted = AuthMessage Auth.VerifySubmitted
    , resetEmailChanged = AuthMessage << Auth.ResetEmailChanged
    , resetRequested = AuthMessage Auth.ResetRequested
    , resetNewPasswordChanged = AuthMessage << Auth.ResetNewPasswordChanged
    , resetSubmitted = AuthMessage Auth.ResetSubmitted
    , changeCurrentPasswordChanged = AuthMessage << Auth.ChangeCurrentPasswordChanged
    , changeNewPasswordChanged = AuthMessage << Auth.ChangeNewPasswordChanged
    , changePasswordSubmitted = AuthMessage Auth.ChangePasswordSubmitted
    }


pagePublicProfile : Model -> Active -> String -> Html Msg
pagePublicProfile model active username =
    Profile.pagePublicProfile (profileViewConfig model) { publicProfile = model.profile.publicProfile, ownProfile = model.profile.ownProfile, profileForm = model.profile.profileForm, auth = model.auth } active username


pageSettings : Model -> Active -> Html Msg
pageSettings model active =
    Profile.pageSettings (profileViewConfig model) { publicProfile = model.profile.publicProfile, ownProfile = model.profile.ownProfile, profileForm = model.profile.profileForm, auth = model.auth } active


profileViewConfig : Model -> Profile.Config Msg
profileViewConfig model =
    { retry = RetryPage
    , profileDisplayNameChanged = ProfileMessage << Profile.ProfileDisplayNameChanged
    , profileAuthoring = ProfileMessage << Profile.ProfileAuthoring
    , profileClearAvatar = ProfileMessage Profile.ProfileClearAvatar
    , profileSave = ProfileMessage Profile.ProfileSave
    , avatarFileSelected = ProfileMessage << Profile.AvatarFileSelected
    , reportPerson = \actor -> ReportMessage (Report.Open (Report.PersonTarget actor))
    }

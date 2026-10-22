module App.Feedback exposing (Flash(..), flashText)

import Api
import Generated.I18n as Translations
import Ui.Feedback exposing (problemText)


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

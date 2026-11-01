module Feature.Auth.State exposing (Model, initial, withResetToken)

import Api


type alias Model =
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
    }


initial : String -> Model
initial token =
    { verificationToken = token
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
    , resetEmail = ""
    , resetProblem = Nothing
    , resetAccepted = False
    , resetToken = ""
    , resetNewPassword = ""
    , resetBusy = False
    , resetComplete = False
    , changeCurrentPassword = ""
    , changeNewPassword = ""
    , changeProblem = Nothing
    , changeBusy = False
    }


withResetToken : String -> Model -> Model
withResetToken token model =
    { model | resetToken = token, resetComplete = False }

module Feature.Auth.State exposing (Model, initial)

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
    }

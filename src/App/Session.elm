module App.Session exposing (AuthState(..))

import Domain


type AuthState
    = CheckingSession
    | Anonymous
    | Authenticated Domain.Identity

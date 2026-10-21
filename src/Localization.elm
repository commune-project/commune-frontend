module Localization exposing
    ( IgnoreReason(..)
    , LoadKind(..)
    , Notice(..)
    , Pending
    , State
    , accept
    , fail
    , initial
    , nobody
    , pending
    , start
    )

import Locale exposing (Locale)


type LoadKind
    = Startup
    | Fallback Locale
    | Switch


type alias Pending =
    { generation : Int
    , target : Locale
    , kind : LoadKind
    }


type Notice
    = None
    | Changed Locale
    | Failed Locale
    | FallbackNotice Locale


type alias State =
    { generation : Int
    , pending : Maybe Pending
    , notice : Notice
    , failedTarget : Maybe Locale
    }


type IgnoreReason
    = Superseded
    | NoPendingRequest


initial : State
initial =
    { generation = 0
    , pending = Nothing
    , notice = None
    , failedTarget = Nothing
    }


start : LoadKind -> Locale -> State -> ( State, Pending )
start kind target state =
    let
        request =
            { generation = state.generation + 1
            , target = target
            , kind = kind
            }
    in
    ( { state | generation = request.generation, pending = Just request, notice = None }
    , request
    )


accept : Pending -> State -> Result IgnoreReason State
accept request state =
    if state.pending /= Just request then
        Err Superseded

    else
        Ok
            { state
                | pending = Nothing
                , notice = noticeFor request.kind request.target
                , failedTarget =
                    case request.kind of
                        Switch ->
                            Nothing

                        _ ->
                            state.failedTarget
            }


fail : Pending -> State -> Result IgnoreReason State
fail request state =
    if state.pending /= Just request then
        Err Superseded

    else
        Ok
            { state
                | pending = Nothing
                , notice =
                    case request.kind of
                        Switch ->
                            Failed request.target

                        _ ->
                            None
                , failedTarget =
                    case request.kind of
                        Fallback original ->
                            Just original

                        _ ->
                            Just request.target
            }


noticeFor : LoadKind -> Locale -> Notice
noticeFor kind target =
    case kind of
        Startup ->
            None

        Switch ->
            Changed target

        Fallback original ->
            FallbackNotice original


pending : State -> Maybe Pending
pending state =
    state.pending


nobody : Result IgnoreReason State -> Maybe State
nobody result =
    Result.toMaybe result

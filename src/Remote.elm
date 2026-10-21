module Remote exposing (Remote(..), fromResult, map, toMaybe)

import Api exposing (Problem)


type Remote a
    = NotAsked
    | Loading
    | Ready a
    | Failed Problem


fromResult : Result Problem a -> Remote a
fromResult result =
    case result of
        Ok value ->
            Ready value

        Err problem ->
            Failed problem


map : (a -> b) -> Remote a -> Remote b
map transform remote =
    case remote of
        NotAsked ->
            NotAsked

        Loading ->
            Loading

        Ready value ->
            Ready (transform value)

        Failed problem ->
            Failed problem


toMaybe : Remote a -> Maybe a
toMaybe remote =
    case remote of
        Ready value ->
            Just value

        _ ->
            Nothing

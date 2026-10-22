port module Ports exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode
import Locale exposing (Locale(..))
import Ui.Formatting exposing (Formatting)


port outgoing : Encode.Value -> Cmd msg


port incoming : (Decode.Value -> msg) -> Sub msg


type IncomingData
    = IncomingCsrf String
    | IncomingFormatting Formatting
    | IncomingIgnored


incomingDecoder : Decode.Decoder IncomingData
incomingDecoder =
    Decode.field "kind" Decode.string
        |> Decode.andThen
            (\kind ->
                case kind of
                    "csrf" ->
                        Decode.map IncomingCsrf (Decode.field "value" Decode.string)

                    "formatted" ->
                        Decode.map IncomingFormatting formattingDecoder

                    _ ->
                        Decode.succeed IncomingIgnored
            )


formattingDecoder : Decode.Decoder Formatting
formattingDecoder =
    Decode.map6 Formatting
        (Decode.field "locale" Decode.string)
        (Decode.at [ "times", "0", "source" ] Decode.string)
        (Decode.at [ "times", "0", "absolute" ] Decode.string)
        (Decode.at [ "times", "0", "relative" ] Decode.string)
        (Decode.field "numbers" (Decode.list pairedIntString))
        (Decode.field "plurals" (Decode.list pairedIntString))


pairedIntString : Decode.Decoder ( Int, String )
pairedIntString =
    Decode.oneOf
        [ Decode.map2 Tuple.pair (Decode.field "source" Decode.int) (Decode.field "text" Decode.string)
        , Decode.map2 Tuple.pair (Decode.field "source" Decode.int) (Decode.field "category" Decode.string)
        ]


requestCsrf : Cmd msg
requestCsrf =
    outgoing (Encode.object [ ( "action", Encode.string "csrf" ) ])


setLocale : Locale -> Cmd msg
setLocale locale =
    outgoing
        (Encode.object
            [ ( "action", Encode.string "locale" )
            , ( "locale", Encode.string (Locale.code locale) )
            ]
        )


requestFormatting : Locale -> Cmd msg
requestFormatting locale =
    outgoing
        (Encode.object
            [ ( "action", Encode.string "format" )
            , ( "locale", Encode.string (Locale.code locale) )
            , ( "times", Encode.list Encode.string [ "2026-10-20T08:30:00Z" ] )
            , ( "numbers", Encode.list Encode.int [ 1, 3, 1234567 ] )
            , ( "plurals", Encode.list Encode.int [ 1, 3 ] )
            ]
        )


focus : String -> Cmd msg
focus identifier =
    outgoing (Encode.object [ ( "action", Encode.string "focus" ), ( "id", Encode.string identifier ) ])


openDialog : String -> Cmd msg
openDialog identifier =
    outgoing (Encode.object [ ( "action", Encode.string "dialog-open" ), ( "id", Encode.string identifier ) ])


closeDialog : String -> Cmd msg
closeDialog identifier =
    outgoing (Encode.object [ ( "action", Encode.string "dialog-close" ), ( "id", Encode.string identifier ) ])

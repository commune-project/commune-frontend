module App.Browser exposing (receiveIncoming)

import App.State exposing (Model, Msg(..))
import Json.Decode as Decode
import Locale exposing (Locale(..))
import Ports exposing (IncomingData(..), incomingDecoder)


receiveIncoming : Decode.Value -> Model -> ( Model, Cmd Msg )
receiveIncoming raw model =
    case Decode.decodeValue incomingDecoder raw of
        Ok (IncomingCsrf value) ->
            ( { model | csrf = value }, Cmd.none )

        Ok (IncomingFormatting currentFormatting) ->
            case model.active of
                Just active ->
                    if currentFormatting.locale == Locale.code active.locale then
                        ( { model | formatted = Just currentFormatting }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        Ok IncomingIgnored ->
            ( model, Cmd.none )

        Err _ ->
            ( model, Cmd.none )

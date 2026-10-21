module Api exposing (Problem, Response, decodeResponse, decodeUnit, get, send, upload)

import File exposing (File)
import Http
import Json.Decode as Decode


type alias Response =
    { status : Int, body : String }


type alias Problem =
    { status : Int, detail : String }


decodeResponse : Decode.Decoder a -> Response -> Result Problem a
decodeResponse decoder response =
    if response.status >= 200 && response.status < 300 then
        Decode.decodeString decoder response.body
            |> Result.mapError (\error -> { status = response.status, detail = Decode.errorToString error })

    else
        Err { status = response.status, detail = response.body }


decodeUnit : Response -> Result Problem ()
decodeUnit response =
    if response.status >= 200 && response.status < 300 then
        Ok ()

    else
        Err { status = response.status, detail = response.body }


expect : (Response -> msg) -> Http.Expect msg
expect toMsg =
    Http.expectStringResponse (\result -> toMsg (Result.withDefault { status = 0, body = "" } result))
        (\response ->
            case response of
                Http.GoodStatus_ metadata body ->
                    Ok { status = metadata.statusCode, body = body }

                Http.BadStatus_ metadata body ->
                    Ok { status = metadata.statusCode, body = body }

                _ ->
                    Ok { status = 0, body = "" }
        )


get : String -> (Response -> msg) -> Cmd msg
get url toMsg =
    Http.get { url = url, expect = expect toMsg }


send : String -> String -> String -> String -> (Response -> msg) -> Cmd msg
send csrf method url body toMsg =
    Http.request
        { method = method
        , headers = [ Http.header "X-CSRF-Token" csrf ]
        , url = url
        , body =
            if body == "" then
                Http.emptyBody

            else
                Http.stringBody "application/json" body
        , expect = expect toMsg
        , timeout = Just 30000
        , tracker = Nothing
        }


upload : String -> String -> File -> (Response -> msg) -> Cmd msg
upload csrf purpose file toMsg =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-CSRF-Token" csrf ]
        , url = "/api/v1/media"
        , body = Http.multipartBody [ Http.stringPart "purpose" purpose, Http.filePart "file" file ]
        , expect = expect toMsg
        , timeout = Just 120000
        , tracker = Nothing
        }

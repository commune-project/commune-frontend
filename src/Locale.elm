module Locale exposing (Locale(..), all, code, formattingLocale, fromString, label, match, negotiate, toLanguage)

import Generated.I18n exposing (Language(..))


type Locale
    = English
    | SimplifiedChinese
    | TraditionalChinese


all : List Locale
all =
    [ English, SimplifiedChinese, TraditionalChinese ]


code : Locale -> String
code locale =
    case locale of
        English ->
            "en-US"

        SimplifiedChinese ->
            "zh-cmn-Hans-CN"

        TraditionalChinese ->
            "zh-cmn-Hant-TW"


label : Locale -> String
label locale =
    case locale of
        English ->
            "English"

        SimplifiedChinese ->
            "简体中文"

        TraditionalChinese ->
            "繁體中文"


formattingLocale : Locale -> String
formattingLocale locale =
    case locale of
        English ->
            "en-US"

        SimplifiedChinese ->
            "zh-Hans-CN"

        TraditionalChinese ->
            "zh-Hant-TW"


toLanguage : Locale -> Language
toLanguage locale =
    case locale of
        English ->
            EnUS

        SimplifiedChinese ->
            ZhCmnHansCN

        TraditionalChinese ->
            ZhCmnHantTW


fromString : String -> Maybe Locale
fromString raw =
    match raw


match : String -> Maybe Locale
match raw =
    let
        parts =
            String.split "-" (String.toLower raw)

        has value =
            List.member value parts
    in
    case List.head parts of
        Just "en" ->
            Just English

        Just "zh" ->
            chinese has

        Just "cmn" ->
            chinese has

        _ ->
            Nothing


chinese : (String -> Bool) -> Maybe Locale
chinese has =
    if has "hant" then
        Just TraditionalChinese

    else if has "hans" then
        Just SimplifiedChinese

    else if has "tw" || has "hk" || has "mo" then
        Just TraditionalChinese

    else
        Just SimplifiedChinese


negotiate : Maybe String -> List String -> Locale
negotiate saved languages =
    (saved |> Maybe.andThen match)
        |> Maybe.withDefault
            (List.filterMap match languages
                |> List.head
                |> Maybe.withDefault English
            )

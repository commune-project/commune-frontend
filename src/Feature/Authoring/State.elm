module Feature.Authoring.State exposing (..)

import Domain
import List


type alias Model =
    { fieldId : String
    , value : String
    , selectionStart : Int
    , selectionEnd : Int
    , mention : Maybe Token
    , status : MentionStatus
    , generation : Int
    , activeIndex : Int
    }


type alias Token =
    { start : Int, end : Int, query : String }


type MentionStatus
    = Closed
    | Typing
    | Pending
    | Loading
    | Ready (List Domain.MentionCandidate)
    | Empty
    | Unavailable


type ToolbarAction
    = Bold
    | Italic
    | Link
    | Code
    | Quote
    | BulletList
    | NumberedList


type alias Replacement =
    { start : Int, end : Int, text : String, caret : Int }


init : String -> String -> Model
init fieldId source =
    { fieldId = fieldId
    , value = source
    , selectionStart = String.length source
    , selectionEnd = String.length source
    , mention = Nothing
    , status = Closed
    , generation = 0
    , activeIndex = 0
    }


value : Model -> String
value model =
    model.value


setValue : String -> Model -> Model
setValue next model =
    { model
        | value = next
        , selectionStart = String.length next
        , selectionEnd = String.length next
        , mention = Nothing
        , status = Closed
        , generation = model.generation + 1
        , activeIndex = 0
    }


setInput : String -> Int -> Int -> Model -> Model
setInput next start end model =
    let
        size =
            String.length next
    in
    { model
        | value = next
        , selectionStart = clamp 0 size start
        , selectionEnd = clamp 0 size end
    }


setSelection : Int -> Int -> Model -> Model
setSelection start end model =
    let
        size =
            String.length model.value
    in
    { model
        | selectionStart = clamp 0 size start
        , selectionEnd = clamp 0 size end
    }


isOpen : Model -> Bool
isOpen model =
    case ( model.mention, model.status ) of
        ( Just _, Pending ) ->
            True

        ( Just _, Loading ) ->
            True

        ( Just _, Ready _ ) ->
            True

        ( Just _, Empty ) ->
            True

        ( Just _, Unavailable ) ->
            True

        _ ->
            False


candidates : Model -> List Domain.MentionCandidate
candidates model =
    case model.status of
        Ready items ->
            items

        _ ->
            []


activeCandidate : Model -> Maybe Domain.MentionCandidate
activeCandidate model =
    candidates model
        |> List.drop model.activeIndex
        |> List.head


tokenQuery : Model -> Maybe String
tokenQuery model =
    model.mention |> Maybe.map .query


detectToken : String -> Int -> Maybe Token
detectToken source caret =
    let
        end =
            clamp 0 (String.length source) caret

        prefix =
            String.slice 0 end source
    in
    case List.reverse (String.indexes "@" prefix) |> List.head of
        Nothing ->
            Nothing

        Just start ->
            if not (validBoundary source start) then
                Nothing

            else
                let
                    query =
                        String.slice (start + 1) end source

                    count =
                        List.length (String.toList query)
                in
                if count == 0 || count > 64 || invalidQuery query then
                    Nothing

                else
                    Just { start = start, end = end, query = query }


validBoundary : String -> Int -> Bool
validBoundary source start =
    if start <= 0 then
        True

    else
        case String.uncons (String.slice (start - 1) start source) of
            Nothing ->
                True

            Just ( before, _ ) ->
                isSpace before
                    || List.member before
                        [ '(', '[', '{', '<', '"', '\'', ',', ';', ':', '!', '?', '。', '，', '、' ]


invalidQuery : String -> Bool
invalidQuery query =
    String.any
        (\character ->
            isSpace character
                || List.member character [ '\\', '/', '?', '#', '[', ']', '(', ')', '<', '>' ]
        )
        query


isSpace : Char -> Bool
isSpace character =
    List.member character [ ' ', '\t', '\n', '\u{000D}', '\u{00A0}', '\u{3000}' ]


format : ToolbarAction -> Model -> Maybe Replacement
format action model =
    let
        start =
            min model.selectionStart model.selectionEnd

        end =
            max model.selectionStart model.selectionEnd

        selected =
            String.slice start end model.value

        selectedLength =
            String.length selected
    in
    case action of
        Bold ->
            Just (wrapped start end selected "**")

        Italic ->
            Just (wrapped start end selected "*")

        Code ->
            Just (wrapped start end selected "`")

        Link ->
            Just (linked start end selected)

        Quote ->
            Just (prefixed start end selected "> ")

        BulletList ->
            Just (prefixed start end selected "- ")

        NumberedList ->
            Just (numbered start end selected)


wrapped : Int -> Int -> String -> String -> Replacement
wrapped start end selected marker =
    { start = start
    , end = end
    , text = marker ++ selected ++ marker
    , caret = start + String.length marker + String.length selected + String.length marker
    }


linked : Int -> Int -> String -> Replacement
linked start end selected =
    if String.isEmpty selected then
        { start = start, end = end, text = "[](https://)", caret = start + 1 }

    else
        let
            text =
                "[" ++ selected ++ "](https://)"
        in
        { start = start, end = end, text = text, caret = start + String.length text }


prefixed : Int -> Int -> String -> String -> Replacement
prefixed start end selected prefix =
    if String.isEmpty selected then
        { start = start, end = end, text = prefix, caret = start + String.length prefix }

    else
        let
            text =
                String.split "\n" selected
                    |> List.map (\line -> prefix ++ line)
                    |> String.join "\n"
        in
        { start = start, end = end, text = text, caret = start + String.length text }


numbered : Int -> Int -> String -> Replacement
numbered start end selected =
    if String.isEmpty selected then
        { start = start, end = end, text = "1. ", caret = start + 3 }

    else
        let
            text =
                String.split "\n" selected
                    |> List.indexedMap (\index line -> String.fromInt (index + 1) ++ ". " ++ line)
                    |> String.join "\n"
        in
        { start = start, end = end, text = text, caret = start + String.length text }


applyReplacement : Replacement -> Model -> Model
applyReplacement replacement model =
    let
        next =
            String.left replacement.start model.value
                ++ replacement.text
                ++ String.dropLeft replacement.end model.value

        size =
            String.length next
    in
    { model
        | value = next
        , selectionStart = clamp 0 size replacement.caret
        , selectionEnd = clamp 0 size replacement.caret
        , mention = Nothing
        , status = Closed
        , generation = model.generation + 1
        , activeIndex = 0
    }


candidateReplacement : Domain.MentionCandidate -> Model -> Maybe Replacement
candidateReplacement candidate model =
    let
        token =
            case model.mention of
                Just current ->
                    Just current

                Nothing ->
                    detectToken model.value model.selectionStart
    in
    case token of
        Just currentToken ->
            if String.isEmpty candidate.acct then
                Nothing

            else
                let
                    text =
                        "@" ++ candidate.acct ++ " "
                in
                Just
                    { start = currentToken.start
                    , end = model.selectionStart
                    , text = text
                    , caret = currentToken.start + String.length text
                    }

        Nothing ->
            Nothing


moveSelection : Int -> Model -> Model
moveSelection delta model =
    let
        count =
            List.length (candidates model)
    in
    if count == 0 then
        model

    else
        { model | activeIndex = modBy count (model.activeIndex + delta) }


closeMention : Model -> Model
closeMention model =
    { model
        | mention = Nothing
        , status = Closed
        , generation = model.generation + 1
        , activeIndex = 0
    }

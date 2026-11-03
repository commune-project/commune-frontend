module Feature.Authoring.Update exposing (Msg(..), Outcome, update)

import Api
import Domain
import Feature.Authoring.State as State exposing (Model, ToolbarAction(..))
import Ports
import Process
import Task
import Url


type Msg
    = Input String Int Int
    | SelectionChanged Int Int
    | Debounce Int
    | CandidatesLoaded Int Api.Response
    | Toolbar ToolbarAction
    | MentionKey String Bool
    | MentionSelected Int
    | DismissMention


type alias Outcome =
    { changed : Bool }


update : Msg -> Model -> ( Model, Cmd Msg, Outcome )
update message model =
    case message of
        Input value start end ->
            let
                ( next, command ) =
                    State.setInput value start end model
                        |> refreshMention
            in
            ( next, command, { changed = value /= model.value } )

        SelectionChanged start end ->
            let
                ( next, command ) =
                    State.setSelection start end model
                        |> refreshMention
            in
            ( next, command, { changed = False } )

        Debounce generation ->
            if generation /= model.generation then
                ( model, Cmd.none, { changed = False } )

            else
                case ( model.mention, model.status ) of
                    ( Just token, State.Pending ) ->
                        ( { model | status = State.Loading }
                        , Api.get
                            ("/api/v1/mentions/candidates?q="
                                ++ Url.percentEncode token.query
                                ++ "&limit=8"
                            )
                            (CandidatesLoaded generation)
                        , { changed = False }
                        )

                    _ ->
                        ( model, Cmd.none, { changed = False } )

        CandidatesLoaded generation response ->
            if generation /= model.generation || model.status /= State.Loading then
                ( model, Cmd.none, { changed = False } )

            else
                case Api.decodeResponse Domain.mentionCandidatePage response of
                    Ok [] ->
                        ( { model | status = State.Empty }, Cmd.none, { changed = False } )

                    Ok items ->
                        ( { model | status = State.Ready items, activeIndex = 0 }, Cmd.none, { changed = False } )

                    Err _ ->
                        ( { model | status = State.Unavailable }, Cmd.none, { changed = False } )

        Toolbar action ->
            case State.format action model of
                Just replacement ->
                    ( State.applyReplacement replacement model
                    , Ports.replaceRange
                        { id = model.fieldId
                        , start = replacement.start
                        , end = replacement.end
                        , text = replacement.text
                        , caret = replacement.caret
                        }
                    , { changed = True }
                    )

                Nothing ->
                    ( model, Cmd.none, { changed = False } )

        MentionKey key composing ->
            if composing || not (State.isOpen model) then
                ( model, Cmd.none, { changed = False } )

            else
                case key of
                    "ArrowDown" ->
                        ( State.moveSelection 1 model, Cmd.none, { changed = False } )

                    "ArrowUp" ->
                        ( State.moveSelection -1 model, Cmd.none, { changed = False } )

                    "Escape" ->
                        ( State.closeMention model, Cmd.none, { changed = False } )

                    "Enter" ->
                        selectActive model

                    "Tab" ->
                        selectActive model

                    _ ->
                        ( model, Cmd.none, { changed = False } )

        MentionSelected index ->
            selectActive { model | activeIndex = index }

        DismissMention ->
            ( State.closeMention model, Cmd.none, { changed = False } )


refreshMention : Model -> ( Model, Cmd Msg )
refreshMention model =
    let
        token =
            State.detectToken model.value model.selectionStart
    in
    case token of
        Nothing ->
            if model.status == State.Closed then
                ( model, Cmd.none )

            else
                ( State.closeMention model, Cmd.none )

        Just next ->
            case model.mention of
                Just current ->
                    if current.query == next.query then
                        ( { model | mention = Just next }, Cmd.none )

                    else
                        startLookup next model

                Nothing ->
                    startLookup next model


startLookup : State.Token -> Model -> ( Model, Cmd Msg )
startLookup token model =
    let
        generation =
            model.generation + 1

        count =
            List.length (String.toList token.query)
    in
    if count < 2 then
        ( { model | mention = Just token, status = State.Typing, generation = generation, activeIndex = 0 }
        , Cmd.none
        )

    else
        ( { model | mention = Just token, status = State.Pending, generation = generation, activeIndex = 0 }
        , Process.sleep 250 |> Task.perform (\_ -> Debounce generation)
        )


selectActive : Model -> ( Model, Cmd Msg, Outcome )
selectActive model =
    case State.activeCandidate model of
        Just candidate ->
            case State.candidateReplacement candidate model of
                Just replacement ->
                    ( State.applyReplacement replacement model
                    , Ports.replaceRange
                        { id = model.fieldId
                        , start = replacement.start
                        , end = replacement.end
                        , text = replacement.text
                        , caret = replacement.caret
                        }
                    , { changed = True }
                    )

                Nothing ->
                    ( State.closeMention model, Cmd.none, { changed = False } )

        Nothing ->
            ( State.closeMention model, Cmd.none, { changed = False } )

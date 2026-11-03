module Feature.Authoring.View exposing (Config, view)

import App.Context exposing (Active)
import Domain
import Feature.Authoring.State as State exposing (Model, ToolbarAction(..))
import Feature.Authoring.Update as Update
import Generated.I18n as Translations
import Html exposing (Html, button, div, img, label, p, span, text, textarea)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Ui.Icon


type alias Config msg =
    { id : String
    , label : String
    , helpId : String
    , helpText : String
    , required : Bool
    , toMsg : Update.Msg -> msg
    }


view : Config msg -> Active -> Model -> Html msg
view config active model =
    let
        open =
            State.isOpen model

        listId =
            config.id ++ "-mention-list"
    in
    div [ A.class "authoring-field" ]
        [ label [ A.for config.id ] [ text config.label ]
        , div [ A.class "authoring-toolbar", A.attribute "role" "toolbar", A.attribute "aria-label" (Translations.formattingToolbar active.texts) ]
            (List.map (toolbarButton config active) toolbarActions)
        , div [ A.class "authoring-editor" ]
            [ textarea
                ([ A.id config.id
                 , A.value model.value
                 , A.dir "auto"
                 , A.required config.required
                 , A.attribute "aria-describedby" config.helpId
                 , A.attribute "role" "combobox"
                 , A.attribute "aria-autocomplete" "list"
                 , A.attribute "aria-haspopup" "listbox"
                 , A.attribute "aria-expanded" (boolString open)
                 , A.attribute "aria-controls" listId
                 , Events.on "input" (inputDecoder config)
                 , Events.on "select" (selectionDecoder config)
                 , Events.on "keyup" (selectionDecoder config)
                 , Events.on "click" (selectionDecoder config)
                 , keydownHandler config model
                 ]
                    ++ activeDescendant config model
                )
                []
            , viewPopup config active model listId
            ]
        , p [ A.id config.helpId, A.class "muted" ] [ text config.helpText ]
        , p [ A.class "sr-only", A.attribute "role" "status", A.attribute "aria-live" "polite" ]
            [ text (statusText active model) ]
        ]


toolbarActions : List ( ToolbarAction, Ui.Icon.Icon, Translations.I18n -> String )
toolbarActions =
    [ ( Bold, Ui.Icon.FormatBold, Translations.formatBold )
    , ( Italic, Ui.Icon.FormatItalic, Translations.formatItalic )
    , ( Link, Ui.Icon.Link, Translations.formatLink )
    , ( Code, Ui.Icon.Code, Translations.formatCode )
    , ( Quote, Ui.Icon.Quote, Translations.formatQuote )
    , ( BulletList, Ui.Icon.BulletList, Translations.formatBulletList )
    , ( NumberedList, Ui.Icon.NumberedList, Translations.formatNumberedList )
    ]


toolbarButton : Config msg -> Active -> ( ToolbarAction, Ui.Icon.Icon, Translations.I18n -> String ) -> Html msg
toolbarButton config active ( action, icon, labelFor ) =
    let
        label =
            labelFor active.texts
    in
    button
        [ A.type_ "button"
        , A.class "icon-button authoring-tool"
        , A.attribute "aria-label" label
        , A.attribute "title" label
        , Events.onClick (config.toMsg (Update.Toolbar action))
        ]
        [ Ui.Icon.view icon ]


viewPopup : Config msg -> Active -> Model -> String -> Html msg
viewPopup config active model listId =
    if not (State.isOpen model) then
        text ""

    else
        div [ A.id listId, A.class "mention-list" ]
            (case model.status of
                State.Ready items ->
                    [ div [ A.attribute "role" "listbox", A.attribute "aria-label" (Translations.mentionSuggestions active.texts) ]
                        (List.indexedMap (viewOption config model) items)
                    ]

                State.Pending ->
                    [ popupStatus (Translations.mentionLoading active.texts) ]

                State.Loading ->
                    [ popupStatus (Translations.mentionLoading active.texts) ]

                State.Empty ->
                    [ popupStatus (Translations.mentionEmpty active.texts) ]

                State.Unavailable ->
                    [ popupStatus (Translations.mentionUnavailable active.texts) ]

                _ ->
                    []
            )


viewOption : Config msg -> Model -> Int -> Domain.MentionCandidate -> Html msg
viewOption config model index candidate =
    let
        selected =
            index == model.activeIndex
    in
    div
        [ A.id (optionId config.id index)
        , A.attribute "role" "option"
        , A.attribute "aria-selected" (boolString selected)
        , A.class "mention-option"
        , Events.preventDefaultOn "mousedown" (Decode.succeed ( config.toMsg (Update.MentionSelected index), True ))
        ]
        [ if String.isEmpty candidate.avatar then
            text ""

          else
            img [ A.src candidate.avatar, A.alt "", A.attribute "referrerpolicy" "no-referrer", A.class "mention-avatar" ] []
        , div [ A.class "mention-copy" ]
            [ span [ A.class "mention-name" ] [ text (candidateName candidate) ]
            , span [ A.class "mention-handle" ] [ text ("@" ++ candidate.acct) ]
            ]
        ]


candidateName : Domain.MentionCandidate -> String
candidateName candidate =
    if String.isEmpty candidate.displayName then
        candidate.acct

    else
        candidate.displayName


popupStatus : String -> Html msg
popupStatus message =
    p [ A.class "mention-status", A.attribute "role" "status" ] [ text message ]


statusText : Active -> Model -> String
statusText active model =
    case model.status of
        State.Pending ->
            Translations.mentionLoading active.texts

        State.Loading ->
            Translations.mentionLoading active.texts

        State.Empty ->
            Translations.mentionEmpty active.texts

        State.Unavailable ->
            Translations.mentionUnavailable active.texts

        _ ->
            ""


activeDescendant : Config msg -> Model -> List (Html.Attribute msg)
activeDescendant config model =
    case ( model.status, State.activeCandidate model ) of
        ( State.Ready _, Just _ ) ->
            [ A.attribute "aria-activedescendant" (optionId config.id model.activeIndex) ]

        _ ->
            []


optionId : String -> Int -> String
optionId fieldId index =
    fieldId ++ "-mention-" ++ String.fromInt index


inputDecoder : Config msg -> Decode.Decoder msg
inputDecoder config =
    Decode.map3 Update.Input
        (Decode.at [ "target", "value" ] Decode.string)
        (Decode.oneOf [ Decode.at [ "target", "selectionStart" ] Decode.int, Decode.succeed 0 ])
        (Decode.oneOf [ Decode.at [ "target", "selectionEnd" ] Decode.int, Decode.succeed 0 ])
        |> Decode.map config.toMsg


selectionDecoder : Config msg -> Decode.Decoder msg
selectionDecoder config =
    Decode.map2 Update.SelectionChanged
        (Decode.oneOf [ Decode.at [ "target", "selectionStart" ] Decode.int, Decode.succeed 0 ])
        (Decode.oneOf [ Decode.at [ "target", "selectionEnd" ] Decode.int, Decode.succeed 0 ])
        |> Decode.map config.toMsg


keydownHandler : Config msg -> Model -> Html.Attribute msg
keydownHandler config model =
    Events.preventDefaultOn "keydown"
        (Decode.map2
            (\key composing ->
                ( config.toMsg (Update.MentionKey key composing)
                , preventKey key composing (State.isOpen model)
                )
            )
            (Decode.field "key" Decode.string)
            (Decode.oneOf [ Decode.field "isComposing" Decode.bool, Decode.succeed False ])
        )


preventKey : String -> Bool -> Bool -> Bool
preventKey key composing open =
    open
        && not composing
        && List.member key [ "ArrowDown", "ArrowUp", "Enter", "Tab", "Escape" ]


boolString : Bool -> String
boolString condition =
    if condition then
        "true"

    else
        "false"

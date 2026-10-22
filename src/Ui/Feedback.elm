module Ui.Feedback exposing (..)

import Api
import Generated.I18n as Translations
import Html exposing (Html, a, button, div, p, text)
import Html.Attributes as A
import Html.Events as Events
import Remote exposing (Remote(..))
import Route


viewRemote : msg -> Translations.I18n -> Remote a -> (a -> Html msg) -> Html msg
viewRemote retry texts remote render =
    case remote of
        NotAsked ->
            text ""

        Loading ->
            p [ A.attribute "role" "status", A.class "loading-state" ] [ text (Translations.loadingMessage texts) ]

        Ready value ->
            render value

        Failed problem ->
            div [ A.class "card field-error", A.attribute "role" "alert" ]
                [ p [] [ text (problemText texts problem) ]
                , button [ A.class "outlined-button", Events.onClick retry ]
                    [ text (Translations.retryLabel texts) ]
                ]


viewFormProblem : Translations.I18n -> Maybe Api.Problem -> Html msg
viewFormProblem texts maybeProblem =
    case maybeProblem of
        Just problem ->
            p [ A.class "field-error", A.attribute "role" "alert" ] [ text (problemText texts problem) ]

        Nothing ->
            text ""


viewFormProblemWith : Translations.I18n -> Maybe String -> Html msg
viewFormProblemWith _ maybeMessage =
    case maybeMessage of
        Just message ->
            p [ A.class "field-error", A.attribute "role" "alert" ] [ text message ]

        Nothing ->
            text ""


viewFormProblemWithId : Translations.I18n -> String -> Maybe String -> Html msg
viewFormProblemWithId _ identifier maybeMessage =
    case maybeMessage of
        Just message ->
            p [ A.id identifier, A.class "field-error", A.attribute "role" "alert" ] [ text message ]

        Nothing ->
            text ""


problemText : Translations.I18n -> Api.Problem -> String
problemText texts problem =
    case problem.status of
        0 ->
            Translations.connectionError texts

        400 ->
            Translations.invalidInput texts

        401 ->
            Translations.sessionExpired texts

        403 ->
            Translations.forbidden texts

        404 ->
            Translations.notFound texts

        409 ->
            if String.contains "edit_conflict" problem.detail then
                Translations.editConflict texts

            else
                Translations.conflict texts

        429 ->
            Translations.rateLimited texts

        503 ->
            Translations.unavailable texts

        _ ->
            Translations.requestFailed texts


emptyState : Translations.I18n -> Html msg
emptyState texts =
    p [ A.class "empty-state" ] [ text (Translations.emptyLatest texts) ]


loginRequired : Translations.I18n -> Html msg
loginRequired texts =
    div [ A.class "card" ]
        [ p [] [ text (Translations.loginRequired texts) ]
        , a [ A.class "filled-button", A.href (Route.path Route.Login) ] [ text (Translations.loginSubmit texts) ]
        ]

module Ui.Formatting exposing (..)

import Generated.I18n as Translations
import List


type alias Formatting =
    { locale : String
    , numbers : List ( Int, String )
    , plurals : List ( Int, String )
    }


likesLabel : Maybe Formatting -> Translations.I18n -> Int -> String
likesLabel model texts count =
    if pluralCategory model count == "one" then
        Translations.likesOne (formattedCount model count) texts

    else
        Translations.likesOther (formattedCount model count) texts


repliesLabel : Maybe Formatting -> Translations.I18n -> Int -> String
repliesLabel model texts count =
    if pluralCategory model count == "one" then
        Translations.repliesOne (formattedCount model count) texts

    else
        Translations.repliesOther (formattedCount model count) texts


upvoteCountLabel : Maybe Formatting -> Translations.I18n -> Int -> String
upvoteCountLabel model texts count =
    if pluralCategory model count == "one" then
        Translations.upvoteCountOne (formattedCount model count) texts

    else
        Translations.upvoteCountOther (formattedCount model count) texts


downvoteCountLabel : Maybe Formatting -> Translations.I18n -> Int -> String
downvoteCountLabel model texts count =
    if pluralCategory model count == "one" then
        Translations.downvoteCountOne (formattedCount model count) texts

    else
        Translations.downvoteCountOther (formattedCount model count) texts


formattedCount : Maybe Formatting -> Int -> String
formattedCount model count =
    case model of
        Just current ->
            current.numbers
                |> List.filter (\( source, _ ) -> source == count)
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.withDefault (String.fromInt count)

        Nothing ->
            String.fromInt count


pluralCategory : Maybe Formatting -> Int -> String
pluralCategory model count =
    case model of
        Just current ->
            current.plurals
                |> List.filter (\( source, _ ) -> source == count)
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.withDefault "other"

        Nothing ->
            "other"


boolText : Bool -> String
boolText value =
    if value then
        "true"

    else
        "false"


policyLabel : Translations.I18n -> String -> String
policyLabel texts policy =
    if policy == "members" then
        Translations.membersOnly texts

    else
        Translations.eligibleUsers texts


modeLabel : Translations.I18n -> String -> String
modeLabel texts mode =
    if mode == "local_only" then
        Translations.localOnly texts

    else
        Translations.federated texts

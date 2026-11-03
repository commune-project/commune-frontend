module Ui.VoteControl exposing (Config, Visibility, view, visibility)

import Generated.I18n as Translations
import Html exposing (Html, div, span, text)
import Html.Attributes as A
import Html.Events as Events
import Ui.Formatting exposing (Formatting, boolText, downvoteCountLabel, formattedCount, upvoteCountLabel)
import Ui.Icon


type alias Config msg =
    { formatted : Maybe Formatting
    , score : Int
    , upvotes : Int
    , downvotes : Int
    , votedByMe : Int
    , canUpvote : Bool
    , canDownvote : Bool
    , canLike : Bool
    , busy : Bool
    , onVote : Int -> msg
    , onLike : Bool -> msg
    }


type alias Visibility =
    { showUp : Bool, showDown : Bool }


visibility : { canUpvote : Bool, canDownvote : Bool, canLike : Bool, votedByMe : Int } -> Visibility
visibility flags =
    { showUp = flags.canUpvote || flags.canLike || flags.votedByMe == 1
    , showDown = flags.canDownvote || flags.votedByMe == -1
    }


view : Config msg -> Translations.I18n -> Html msg
view config texts =
    let
        upActive =
            config.votedByMe == 1

        downActive =
            config.votedByMe == -1

        visible =
            visibility
                { canUpvote = config.canUpvote
                , canDownvote = config.canDownvote
                , canLike = config.canLike
                , votedByMe = config.votedByMe
                }

        showUp =
            visible.showUp

        showDown =
            visible.showDown

        scoreText =
            formattedCount config.formatted config.score

        scoreLabel =
            Translations.voteScore scoreText texts

        breakdown =
            Translations.voteBreakdown
                (upvoteCountLabel config.formatted texts config.upvotes
                    ++ " · "
                    ++ downvoteCountLabel config.formatted texts config.downvotes
                )
                texts

        upMessage =
            if config.canUpvote then
                config.onVote
                    (if upActive then
                        0

                     else
                        1
                    )

            else if config.canLike then
                config.onLike upActive

            else
                config.onVote 0

        downMessage =
            config.onVote
                (if downActive then
                    0

                 else
                    -1
                )
    in
    if not showUp && not showDown then
        if config.score == 0 then
            text ""

        else
            div [ A.class "vote-control vote-control-readonly", A.attribute "role" "group", A.attribute "aria-label" (Translations.voteGroup texts ++ ", " ++ scoreLabel), A.attribute "title" breakdown ]
                [ span [ A.class "vote-score" ] [ text scoreText ] ]

    else
        div
            [ A.class "vote-control"
            , A.attribute "role" "group"
            , A.attribute "aria-label" (Translations.voteGroup texts ++ ", " ++ scoreLabel)
            , A.attribute "title" breakdown
            , A.attribute "aria-busy" (boolText config.busy)
            ]
            (List.filterMap identity
                [ if showUp then
                    Just (voteButton texts config Translations.upvote config.busy upActive upMessage Ui.Icon.ThumbUp)

                  else
                    Nothing
                , Just (span [ A.class "vote-score" ] [ text scoreText ])
                , if showDown then
                    Just (voteButton texts config Translations.downvote config.busy downActive downMessage Ui.Icon.ThumbDown)

                  else
                    Nothing
                ]
            )


voteButton : Translations.I18n -> Config msg -> (Translations.I18n -> String) -> Bool -> Bool -> msg -> (Bool -> Ui.Icon.Icon) -> Html msg
voteButton texts config labelFor busy active action iconFor =
    let
        actionLabel =
            if active then
                Translations.clearVote texts

            else
                labelFor texts

        scoreLabel =
            Translations.voteScore (formattedCount config.formatted config.score) texts

        name =
            actionLabel ++ " · " ++ scoreLabel
    in
    Html.button
        [ A.class
            ("icon-button vote-button"
                ++ (if active then
                        " vote-active"

                    else
                        ""
                   )
            )
        , A.attribute "aria-label" name
        , A.attribute "title" name
        , A.attribute "aria-pressed" (boolText active)
        , A.disabled busy
        , Events.onClick action
        ]
        [ Ui.Icon.view (iconFor active) ]

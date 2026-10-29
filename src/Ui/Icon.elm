module Ui.Icon exposing (Icon(..), view)

import Generated.Icons as Icons
import Html exposing (Html)
import Html.Attributes as A
import Svg exposing (path, svg)
import Svg.Attributes as SA


type Icon
    = Like Bool
    | Edit
    | Delete
    | Reply


view : Icon -> Html msg
view icon =
    svg
        [ SA.viewBox "0 0 24 24"
        , SA.width "24"
        , SA.height "24"
        , SA.fill "currentColor"
        , A.attribute "class" "icon"
        , A.attribute "aria-hidden" "true"
        , A.attribute "focusable" "false"
        ]
        [ path [ SA.d (data icon) ] [] ]


data : Icon -> String
data icon =
    case icon of
        Like True ->
            Icons.favorite

        Like False ->
            Icons.favoriteBorder

        Edit ->
            Icons.edit

        Delete ->
            Icons.delete

        Reply ->
            Icons.chatBubbleOutline

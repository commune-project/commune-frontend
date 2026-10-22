module Ui.Layout exposing (pageHeading)

import Html exposing (Html, h1, section, text)
import Html.Attributes as A


pageHeading : String -> Html msg -> Html msg
pageHeading title content =
    section [ A.class "primary-column" ]
        [ h1 [ A.id "main-heading", A.tabindex -1, A.dir "auto" ] [ text title ]
        , content
        ]

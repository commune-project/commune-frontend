module Ui.Layout exposing (entityHeading, pageHeading)

import Html exposing (Html, h1, section, text)
import Html.Attributes as A


pageHeading : String -> Html msg -> Html msg
pageHeading title content =
    heading "page-heading" title content


entityHeading : String -> Html msg -> Html msg
entityHeading title content =
    heading "page-heading page-heading-entity" title content


heading : String -> String -> Html msg -> Html msg
heading headingClass title content =
    section [ A.class "primary-column" ]
        [ h1 [ A.id "main-heading", A.class headingClass, A.tabindex -1, A.dir "auto" ] [ text title ]
        , content
        ]

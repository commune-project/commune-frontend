module Ui.Pagination exposing (..)

import Domain
import Generated.I18n as Translations
import Html exposing (Html, a, div, p, text)
import Html.Attributes as A
import Route
import Url exposing (Url)


viewPagination : Translations.I18n -> Url -> Int -> Int -> Int -> Html msg
viewPagination texts url offset limit count =
    div [ A.class "pagination" ]
        [ if offset > 0 then
            a [ A.class "outlined-button", A.href (Route.pageUrl url (max 0 (offset - limit))) ]
                [ text (Translations.previousPage texts) ]

          else
            text ""
        , if count >= limit then
            a [ A.class "outlined-button", A.href (Route.pageUrl url (offset + limit)) ]
                [ text (Translations.nextPage texts) ]

          else
            text ""
        ]


emptyWithPagination : Translations.I18n -> Url -> Domain.Page a -> Html msg
emptyWithPagination texts url page =
    div [ A.class "stack" ]
        [ p [ A.class "empty-state" ] [ text (Translations.emptyLatest texts) ]
        , viewPagination texts url page.offset page.limit 0
        ]

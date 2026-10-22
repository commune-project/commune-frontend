module Ui.CommunityPolicy exposing (policyFields)

import App.Context exposing (Active)
import Generated.I18n as Translations
import Html exposing (Html, div, label, option, select, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode


policyFields :
    Active
    -> String
    -> String
    -> (String -> msg)
    -> (String -> msg)
    -> Html msg
policyFields active readPolicy postPolicy onRead onPost =
    div [ A.class "form-grid" ]
        [ div []
            [ label [ A.for "read-policy" ] [ text (Translations.readPolicy active.texts) ]
            , select [ A.id "read-policy", Events.on "change" (Decode.map onRead (Decode.at [ "target", "value" ] Decode.string)) ]
                [ option [ A.value "eligible_users", A.selected (readPolicy == "eligible_users") ] [ text (Translations.eligibleUsers active.texts) ]
                , option [ A.value "members", A.selected (readPolicy == "members") ] [ text (Translations.membersOnly active.texts) ]
                ]
            ]
        , div []
            [ label [ A.for "post-policy" ] [ text (Translations.postPolicy active.texts) ]
            , select [ A.id "post-policy", Events.on "change" (Decode.map onPost (Decode.at [ "target", "value" ] Decode.string)) ]
                [ option [ A.value "eligible_users", A.selected (postPolicy == "eligible_users") ] [ text (Translations.eligibleUsers active.texts) ]
                , option [ A.value "members", A.selected (postPolicy == "members") ] [ text (Translations.membersOnly active.texts) ]
                ]
            ]
        ]

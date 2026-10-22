module Ui.CommunityCard exposing (communityCard)

import Domain
import Generated.I18n as Translations
import Html exposing (Html, a, article, h2, p, span, text)
import Html.Attributes as A
import Route
import Ui.Formatting exposing (modeLabel, policyLabel)


communityCard : Translations.I18n -> Domain.Community -> Html msg
communityCard texts community =
    article [ A.class "card" ]
        [ h2 [] [ a [ A.href (Route.path (Route.Community community.id)) ] [ text community.title ] ]
        , if String.isEmpty community.description then
            text ""

          else
            p [ A.dir "auto" ] [ text community.description ]
        , p [ A.class "metadata" ]
            [ text
                (Translations.policySummary
                    { read = policyLabel texts community.readPolicy
                    , post = policyLabel texts community.postPolicy
                    }
                    texts
                )
            ]
        , p [ A.class "chips" ]
            [ span [ A.class "chip" ] [ text (modeLabel texts community.mode) ]
            , span [ A.class "chip" ] [ text (policyLabel texts community.readPolicy) ]
            ]
        ]

module Feature.Feed exposing (Config, Model, Msg(..), initial, load, pageLatest, update)

import Api
import App.Context exposing (Active)
import Domain
import Generated.I18n as Translations
import Html exposing (Html, div)
import Html.Attributes as A
import List
import Remote exposing (Remote(..))
import Route
import Ui.Feedback exposing (viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)


type alias Model =
    { topics : Remote (Domain.Page Domain.Post)
    }


initial : Model
initial =
    { topics = NotAsked }


type Msg
    = Loaded Api.Response


sessionProblem : Api.Problem -> Maybe Api.Problem
sessionProblem problem =
    if problem.status == 401 then
        Just problem

    else
        Nothing


update : Msg -> Model -> ( Model, Maybe Api.Problem )
update message model =
    case message of
        Loaded response ->
            case Api.decodeResponse (Domain.page Domain.post) response of
                Ok page ->
                    ( { topics = Ready page }, Nothing )

                Err problem ->
                    ( { topics = Failed problem }, sessionProblem problem )


load : Url -> ( Model, Cmd Msg )
load url =
    ( { topics = Loading }, Api.get ("/api/v1/topics?limit=20&offset=" ++ String.fromInt (Route.offset url)) Loaded )


type alias Config msg =
    { retry : msg
    , postCard : Domain.Post -> Html msg
    }


type alias ViewModel =
    { topics : Remote (Domain.Page Domain.Post)
    , url : Url
    }


pageLatest : Config msg -> ViewModel -> Active -> Html msg
pageLatest config model active =
    pageHeading (Translations.latestTitle active.texts)
        (viewRemote config.retry
            active.texts
            model.topics
            (\page ->
                if List.isEmpty page.items then
                    emptyWithPagination active.texts model.url page

                else
                    div [ A.class "stack" ]
                        [ div [ A.class "stack" ] (List.map config.postCard page.items)
                        , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                        ]
            )
        )

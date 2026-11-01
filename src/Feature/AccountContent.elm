module Feature.AccountContent exposing (Config, Model, Msg(..), initial, load, pageAccountContent, reset, update)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Domain
import Generated.I18n as Translations
import Html exposing (Html, div, p, text)
import Html.Attributes as A
import List
import Remote exposing (Remote(..))
import Route
import Ui.Feedback exposing (loginRequired, viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)


type alias Model =
    { posts : Remote (Domain.Page Domain.Post) }


initial : Model
initial =
    { posts = NotAsked }


reset : Model -> Model
reset model =
    { model | posts = NotAsked }


type Msg
    = Loaded Api.Response


update : Msg -> Model -> ( Model, Maybe Api.Problem )
update message model =
    case message of
        Loaded response ->
            case Api.decodeResponse (Domain.page Domain.post) response of
                Ok page ->
                    ( { model | posts = Ready page }, Nothing )

                Err problem ->
                    ( { model | posts = Failed problem }
                    , if problem.status == 401 then
                        Just problem

                      else
                        Nothing
                    )


sourceName : Domain.AccountContentSource -> String
sourceName source =
    case source of
        Domain.SavedContent ->
            "saved"

        Domain.ReadContent ->
            "read"

        Domain.HiddenContent ->
            "hidden"

        Domain.LikedContent ->
            "liked"


load : Domain.AccountContentSource -> Url -> Model -> ( Model, Cmd Msg )
load source url model =
    ( { model | posts = Loading }
    , Api.get
        ("/api/v1/account/"
            ++ sourceName source
            ++ "?limit=20&offset="
            ++ String.fromInt (Route.offset url)
        )
        Loaded
    )


sourceTitle : Translations.I18n -> Domain.AccountContentSource -> String
sourceTitle texts source =
    case source of
        Domain.SavedContent ->
            Translations.savedPostsTitle texts

        Domain.ReadContent ->
            Translations.readPostsTitle texts

        Domain.HiddenContent ->
            Translations.hiddenPostsTitle texts

        Domain.LikedContent ->
            Translations.likedPostsTitle texts


type alias Config msg =
    { retry : msg
    , postCard : Domain.Post -> Html msg
    }


type alias ViewModel =
    { posts : Remote (Domain.Page Domain.Post)
    , auth : AuthState
    , url : Url
    }


pageAccountContent : Config msg -> ViewModel -> Active -> Domain.AccountContentSource -> Html msg
pageAccountContent config model active source =
    pageHeading (sourceTitle active.texts source)
        (case model.auth of
            Authenticated _ ->
                div [ A.class "stack" ]
                    [ p [ A.class "muted" ] [ text (Translations.accountContentIntro active.texts) ]
                    , viewRemote config.retry
                        active.texts
                        model.posts
                        (\page ->
                            if List.isEmpty page.items then
                                emptyWithPagination active.texts model.url page

                            else
                                div [ A.class "stack" ]
                                    [ div [ A.class "stack" ] (List.map config.postCard page.items)
                                    , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                                    ]
                        )
                    ]

            _ ->
                loginRequired active.texts
        )

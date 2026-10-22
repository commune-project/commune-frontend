module Feature.Search exposing (Config, Model, Msg(..), Outcome, SearchResult(..), SearchState, emptySearch, initial, load, pageSearch, update)

import Api
import App.Context exposing (Active)
import Domain
import Generated.I18n as Translations
import Html exposing (Html, button, div, form, input, label, option, p, section, select, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import List
import Remote exposing (Remote(..))
import Route
import Ui.CommunityCard exposing (communityCard)
import Ui.Feedback exposing (viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)
import Url.Builder as Builder


type SearchResult
    = PostSearch (Domain.Page Domain.Post)
    | CommunitySearch (Domain.Page Domain.Community)


type alias SearchState =
    { kind : String
    , query : String
    , results : Remote SearchResult
    }


emptySearch : SearchState
emptySearch =
    { kind = "posts", query = "", results = NotAsked }


type alias Model =
    { search : SearchState }


initial : Model
initial =
    { search = emptySearch }


type Msg
    = SearchKindChanged String
    | SearchQueryChanged String
    | SearchSubmitted
    | Loaded String Api.Response


type alias Outcome =
    { navigation : Maybe String, sessionProblem : Maybe Api.Problem }


update : Msg -> Model -> ( Model, Cmd Msg, Outcome )
update message model =
    let
        keep next navigation problem =
            ( next, Cmd.none, { navigation = navigation, sessionProblem = problem } )
    in
    case message of
        SearchKindChanged kind ->
            keep { search = (\search -> { search | kind = kind }) model.search } Nothing Nothing

        SearchQueryChanged query ->
            keep { search = (\search -> { search | query = query }) model.search } Nothing Nothing

        SearchSubmitted ->
            let
                query =
                    String.trim model.search.query
            in
            if String.isEmpty query then
                keep { search = (\search -> { search | results = NotAsked }) model.search } Nothing Nothing

            else
                keep model (Just ("/search" ++ Builder.toQuery [ Builder.string "kind" model.search.kind, Builder.string "q" query ])) Nothing

        Loaded kind response ->
            let
                decoder =
                    if kind == "communities" then
                        Decode.map CommunitySearch (Domain.page Domain.community)

                    else
                        Decode.map PostSearch (Domain.page Domain.post)
            in
            case Api.decodeResponse decoder response of
                Ok results ->
                    keep { search = (\search -> { search | results = Ready results }) model.search } Nothing Nothing

                Err problem ->
                    keep { search = (\search -> { search | results = Failed problem }) model.search }
                        Nothing
                        (if problem.status == 401 then
                            Just problem

                         else
                            Nothing
                        )


load : Url -> ( Model, Cmd Msg )
load url =
    let
        kind =
            if Route.query "kind" url == "communities" then
                "communities"

            else
                "posts"

        query =
            Route.query "q" url

        empty =
            String.isEmpty (String.trim query)
    in
    ( { search =
            { kind = kind
            , query = query
            , results =
                if empty then
                    NotAsked

                else
                    Loading
            }
      }
    , if empty then
        Cmd.none

      else
        Api.get ("/api/v1/search" ++ Builder.toQuery [ Builder.string "kind" kind, Builder.string "q" query, Builder.int "offset" (Route.offset url) ]) (Loaded kind)
    )


type alias Config msg =
    { retry : msg
    , searchKindChanged : String -> msg
    , searchQueryChanged : String -> msg
    , searchSubmitted : msg
    , postCard : Domain.Post -> Html msg
    }


type alias ViewModel =
    { search : SearchState
    , url : Url
    }


pageSearch : Config msg -> ViewModel -> Active -> Html msg
pageSearch config model active =
    pageHeading (Translations.searchTitle active.texts)
        (section [ A.class "primary-column" ]
            [ form [ Events.onSubmit config.searchSubmitted, A.class "card form-stack" ]
                [ p [ A.class "muted" ] [ text (Translations.searchIntro active.texts) ]
                , div []
                    [ label [ A.for "search-kind" ] [ text (Translations.searchType active.texts) ]
                    , select [ A.id "search-kind", Events.on "change" (Decode.map config.searchKindChanged (Decode.at [ "target", "value" ] Decode.string)) ]
                        [ option [ A.value "posts", A.selected (model.search.kind == "posts") ] [ text (Translations.searchPosts active.texts) ]
                        , option [ A.value "communities", A.selected (model.search.kind == "communities") ] [ text (Translations.searchCommunities active.texts) ]
                        ]
                    ]
                , div []
                    [ label [ A.for "search-query" ] [ text (Translations.searchQuery active.texts) ]
                    , input [ A.id "search-query", A.type_ "search", A.required True, A.value model.search.query, Events.onInput config.searchQueryChanged ]
                        []
                    ]
                , button [ A.type_ "submit", A.class "filled-button" ] [ text (Translations.searchSubmit active.texts) ]
                ]
            , viewRemote config.retry
                active.texts
                model.search.results
                (\result ->
                    case result of
                        PostSearch page ->
                            if List.isEmpty page.items then
                                emptyWithPagination active.texts model.url page

                            else
                                div [ A.class "stack" ]
                                    [ div [ A.class "stack" ] (List.map config.postCard page.items)
                                    , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                                    ]

                        CommunitySearch page ->
                            if List.isEmpty page.items then
                                emptyWithPagination active.texts model.url page

                            else
                                div [ A.class "stack" ]
                                    [ div [ A.class "stack" ] (List.map (communityCard active.texts) page.items)
                                    , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
                                    ]
                )
            ]
        )

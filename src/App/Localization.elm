module App.Localization exposing (beginStartup, catalog, loadCatalog, resolveCatalog, selectLocale)

import App.State exposing (Model, Msg(..))
import Generated.I18n as Translations
import Http
import Locale exposing (Locale(..))
import Localization exposing (LoadKind(..))
import Ports exposing (focus, requestFormatting, setLocale)


selectLocale : String -> Model -> ( Model, Cmd Msg )
selectLocale raw model =
    case Locale.fromString raw of
        Nothing ->
            ( model, Cmd.none )

        Just target ->
            case model.active of
                Just active ->
                    if active.locale == target then
                        ( model, focus "language-select" )

                    else
                        beginSwitch target model

                Nothing ->
                    beginStartup target model


beginStartup : Locale -> Model -> ( Model, Cmd Msg )
beginStartup target model =
    let
        ( loading, request ) =
            Localization.start Startup target model.loading
    in
    ( { model | requested = target, loading = loading, bootFailed = False }
    , loadCatalog request
    )


beginSwitch : Locale -> Model -> ( Model, Cmd Msg )
beginSwitch target model =
    let
        ( loading, request ) =
            Localization.start Switch target model.loading
    in
    ( { model | requested = target, loading = loading }
    , loadCatalog request
    )


resolveCatalog :
    Localization.Pending
    -> Result Http.Error (Translations.I18n -> Translations.I18n)
    -> Model
    -> ( Model, Cmd Msg )
resolveCatalog request result model =
    case result |> Result.map (\apply -> apply (catalog request.target)) of
        Err _ ->
            rejectCatalog request model

        Ok texts ->
            if
                Translations.arrivedLanguage texts
                    == Locale.toLanguage request.target
                    && Translations.catalogId texts
                    == Locale.code request.target
            then
                acceptCatalog request texts model

            else
                rejectCatalog request model


acceptCatalog : Localization.Pending -> Translations.I18n -> Model -> ( Model, Cmd Msg )
acceptCatalog request texts model =
    case Localization.accept request model.loading of
        Err _ ->
            ( model, Cmd.none )

        Ok loading ->
            let
                active =
                    { locale = request.target, texts = texts }

                focusTarget =
                    case request.kind of
                        Switch ->
                            "language-select"

                        _ ->
                            "main-heading"
            in
            ( { model | active = Just active, requested = request.target, loading = loading, bootFailed = False }
            , Cmd.batch
                [ setLocale active.locale
                , requestFormatting active.locale
                , focus focusTarget
                ]
            )


rejectCatalog : Localization.Pending -> Model -> ( Model, Cmd Msg )
rejectCatalog request model =
    case Localization.fail request model.loading of
        Err _ ->
            ( model, Cmd.none )

        Ok failed ->
            case request.kind of
                Startup ->
                    startFallback request failed model

                Fallback _ ->
                    ( { model | loading = failed, bootFailed = True }, Cmd.none )

                Switch ->
                    ( { model | loading = failed }, focus "language-select" )


startFallback : Localization.Pending -> Localization.State -> Model -> ( Model, Cmd Msg )
startFallback failedRequest failed model =
    if failedRequest.target == English then
        ( { model | loading = failed, bootFailed = True }, Cmd.none )

    else
        let
            ( loading, request ) =
                Localization.start (Fallback failedRequest.target) English failed
        in
        ( { model | loading = loading, requested = failedRequest.target, bootFailed = False }
        , loadCatalog request
        )


loadCatalog : Localization.Pending -> Cmd Msg
loadCatalog request =
    Translations.loadMessages (CatalogResult request) (catalog request.target)


catalog : Locale -> Translations.I18n
catalog locale =
    Translations.init { lang = Locale.toLanguage locale, path = "/assets/i18n" }

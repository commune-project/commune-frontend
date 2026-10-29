module App.Shell exposing (viewBoot, viewReady)

import App.Context exposing (Active)
import App.Feedback exposing (Flash(..), flashText)
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Feature.Auth.Update as Auth
import Generated.I18n as Translations
import Html exposing (Html, a, bdi, button, div, h1, h2, header, img, label, main_, nav, option, p, section, select, span, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import List
import Locale exposing (Locale(..))
import Localization
import Remote exposing (Remote(..))
import Route
import Ui.Formatting exposing (boolText)
import Ui.Icon as Icon


viewBoot : Model -> Html Msg
viewBoot model =
    div [ A.class "app-shell" ]
        [ main_ [ A.id "main-content", A.class "boot-shell" ]
            [ h1 [ A.id "main-heading", A.tabindex -1, A.class "boot-brand" ] [ text "Commune" ]
            , if model.bootFailed then
                bootFailure model

              else
                div [ A.class "boot-progress", A.attribute "role" "progressbar", A.attribute "aria-label" "Commune" ]
                    [ div [ A.class "loading-dot", A.attribute "aria-hidden" "true" ] [] ]
            ]
        ]


bootFailure : Model -> Html Msg
bootFailure model =
    section [ A.class "card error-shell", A.attribute "aria-labelledby" "boot-error-title" ]
        [ h2 [ A.id "boot-error-title" ] [ text "Interface translations are unavailable" ]
        , p [] [ text "Check your connection, then retry or choose another language." ]
        , label [ A.for "boot-language-select" ] [ text "Language" ]
        , languageSelect "boot-language-select" BootLanguageSelected model.requested
        , button [ A.class "filled-button", Events.onClick RetryLocalization ] [ text "Try again" ]
        ]


viewReady : Html Msg -> Model -> Active -> Html Msg
viewReady content model active =
    div [ A.class "app-shell" ]
        [ viewTopBar model active
        , div
            [ A.class
                ("shell-body"
                    ++ (if model.wideLayout && model.drawerOpen then
                            " with-drawer"

                        else
                            ""
                       )
                )
            ]
            [ if model.wideLayout && model.drawerOpen then
                viewPermanentDrawer model active

              else
                text ""
            , div [ A.class "content-column" ]
                [ main_ [ A.id "main-content", A.class "page-content", A.tabindex -1 ]
                    [ viewLocaleNotice model active
                    , viewFlash model active
                    , content
                    ]
                ]
            ]
        , if model.wideLayout then
            text ""

          else
            viewModalDrawer model active
        , viewConfirmation model active
        ]


viewTopBar : Model -> Active -> Html Msg
viewTopBar model active =
    header [ A.class "top-bar" ]
        [ a [ A.href "#main-content", A.class "skip-link" ] [ text (Translations.skipLink active.texts) ]
        , button
            [ A.id "menu-button"
            , A.class "icon-button"
            , A.attribute "aria-expanded" (boolText model.drawerOpen)
            , A.attribute "aria-controls" "navigation-drawer"
            , A.attribute "aria-label"
                (if model.drawerOpen then
                    Translations.closeMenu active.texts

                 else
                    Translations.openMenu active.texts
                )
            , Events.onClick
                (if model.drawerOpen then
                    CloseDrawer

                 else
                    OpenDrawer
                )
            ]
            [ Icon.view Icon.Menu ]
        , a [ A.href "/", A.class "brand" ] [ text (Translations.appTitle active.texts) ]
        ]


viewPermanentDrawer : Model -> Active -> Html Msg
viewPermanentDrawer model active =
    Html.node "aside"
        [ A.id "navigation-drawer", A.class "drawer drawer-permanent" ]
        (drawerContent model active [])


viewModalDrawer : Model -> Active -> Html Msg
viewModalDrawer model active =
    if model.drawerOpen then
        Html.node "dialog"
            [ A.id "navigation-drawer"
            , A.class "drawer drawer-modal"
            , A.attribute "aria-labelledby" "drawer-title"
            , Events.on "close" (Decode.succeed DrawerClosed)
            , Events.on "cancel" (Decode.succeed CloseDrawer)
            ]
            [ div [ A.class "drawer-modal-head" ]
                [ h2 [ A.id "drawer-title", A.class "drawer-title" ] [ text (Translations.mainNavigation active.texts) ]
                , button
                    [ A.class "icon-button drawer-close"
                    , A.attribute "aria-label" (Translations.closeMenu active.texts)
                    , Events.onClick CloseDrawer
                    ]
                    [ Icon.view Icon.Close ]
                ]
            , div [ A.class "drawer-scroll" ]
                (drawerContent model active [ Events.onClick CloseDrawer ])
            ]

    else
        text ""


drawerContent : Model -> Active -> List (Html.Attribute Msg) -> List (Html Msg)
drawerContent model active extras =
    viewDrawerProfile model active
        :: [ nav
                [ A.class "drawer-nav"
                , A.attribute "aria-label" (Translations.mainNavigation active.texts)
                ]
                (drawerLinks model active extras
                    ++ [ div [ A.class "drawer-divider", A.attribute "role" "separator" ] [] ]
                    ++ drawerAccount model active extras
                )
           , div [ A.class "drawer-footer" ]
                [ label [ A.for "language-select" ] [ text (Translations.languageLabel active.texts) ]
                , languageSelect "language-select" LanguageSelected active.locale
                , pendingIndicator model active
                ]
           ]


viewDrawerProfile : Model -> Active -> Html Msg
viewDrawerProfile model active =
    case model.auth of
        Authenticated account ->
            let
                ( displayName, avatarUrl ) =
                    case model.drawerProfile of
                        Ready profile ->
                            ( if String.isEmpty profile.name then
                                account.username

                              else
                                profile.name
                            , profile.avatar
                            )

                        _ ->
                            ( account.username, "" )

                roles =
                    List.filterMap identity
                        [ if account.siteAdmin then
                            Just (Translations.siteAdministrator active.texts)

                          else
                            Nothing
                        , if account.deploymentAdmin then
                            Just (Translations.deploymentAdministrator active.texts)

                          else
                            Nothing
                        ]

                meta =
                    "@"
                        ++ account.username
                        ++ (if List.isEmpty roles then
                                ""

                            else
                                " · " ++ String.join " · " roles
                           )
            in
            div [ A.class "drawer-profile" ]
                [ if String.isEmpty avatarUrl then
                    span
                        [ A.class "drawer-avatar drawer-avatar-placeholder"
                        , A.attribute "aria-hidden" "true"
                        ]
                        [ text (String.left 1 account.username) ]

                  else
                    img
                        [ A.src avatarUrl
                        , A.alt ""
                        , A.class "drawer-avatar"
                        , A.attribute "referrerpolicy" "no-referrer"
                        ]
                        []
                , div [ A.class "drawer-identity" ]
                    [ p [ A.class "drawer-name" ] [ text displayName ]
                    , p [ A.class "drawer-meta" ] [ bdi [] [ text meta ] ]
                    ]
                ]

        _ ->
            a [ A.href (Route.path Route.Login), A.class "drawer-profile drawer-profile-anonymous" ]
                [ span
                    [ A.class "drawer-avatar drawer-avatar-placeholder"
                    , A.attribute "aria-hidden" "true"
                    ]
                    [ Icon.view Icon.Person ]
                , span [ A.class "drawer-name" ] [ text (Translations.navLogin active.texts) ]
                ]


drawerLinks : Model -> Active -> List (Html.Attribute Msg) -> List (Html Msg)
drawerLinks model active extras =
    let
        texts =
            active.texts
    in
    [ drawerLink model active Route.Latest Icon.Home (Translations.navLatest texts) extras
    , drawerLink model active Route.Communities Icon.Communities (Translations.navCommunities texts) extras
    , drawerLink model active Route.Search Icon.Search (Translations.navSearch texts) extras
    , drawerNotificationLink model active extras
    ]


drawerLink : Model -> Active -> Route.Route -> Icon.Icon -> String -> List (Html.Attribute Msg) -> Html Msg
drawerLink model _ target icon labelText extras =
    a
        ((A.href (Route.path target) :: A.class "drawer-item" :: extras)
            ++ currentAttributes model target
        )
        [ Icon.view icon
        , span [ A.class "drawer-label" ] [ text labelText ]
        ]


drawerNotificationLink : Model -> Active -> List (Html.Attribute Msg) -> Html Msg
drawerNotificationLink model active extras =
    let
        labelText =
            Translations.navNotifications active.texts

        accessibleLabel =
            case model.notificationsPage.unreadCount of
                Just count ->
                    labelText ++ " (" ++ count ++ ")"

                Nothing ->
                    labelText
    in
    a
        ((A.href (Route.path Route.Notifications)
            :: A.class "drawer-item"
            :: A.attribute "aria-label" accessibleLabel
            :: extras
         )
            ++ currentAttributes model Route.Notifications
        )
        [ Icon.view Icon.Notifications
        , span [ A.class "drawer-label" ] [ text labelText ]
        , case model.notificationsPage.unreadCount of
            Just count ->
                span [ A.class "drawer-badge", A.attribute "aria-hidden" "true" ] [ text count ]

            Nothing ->
                text ""
        ]


drawerAccount : Model -> Active -> List (Html.Attribute Msg) -> List (Html Msg)
drawerAccount model active extras =
    let
        texts =
            active.texts
    in
    case model.auth of
        Authenticated account ->
            [ drawerLink model active (Route.Profile account.username) Icon.Person (Translations.navProfile texts) extras
            , drawerLink model active Route.Settings Icon.Settings (Translations.navSettings texts) extras
            , button
                ((A.class "drawer-item drawer-action" :: extras)
                    ++ [ Events.onClick (AuthMessage Auth.Logout) ]
                )
                [ Icon.view Icon.Logout
                , span [ A.class "drawer-label" ] [ text (Translations.logout texts) ]
                ]
            ]

        _ ->
            [ drawerLink model active Route.Login Icon.Login (Translations.navLogin texts) extras ]


currentAttributes : Model -> Route.Route -> List (Html.Attribute Msg)
currentAttributes model target =
    if model.route == target then
        [ A.attribute "aria-current" "page" ]

    else
        []


viewConfirmation : Model -> Active -> Html Msg
viewConfirmation model active =
    case model.dialog of
        Just postId ->
            Html.node "dialog"
                [ A.id "confirmation-dialog"
                , A.class "confirmation"
                , A.attribute "aria-labelledby" "confirmation-title"
                , Events.on "close" (Decode.succeed CloseDialog)
                , Events.on "cancel" (Decode.succeed CloseDialog)
                ]
                [ h2 [ A.id "confirmation-title" ] [ text (Translations.confirmDeleteTitle active.texts) ]
                , p [] [ text (Translations.confirmDeleteHelp active.texts) ]
                , div [ A.class "dialog-actions" ]
                    [ button [ A.class "text-button", Events.onClick CloseDialog ] [ text (Translations.cancel active.texts) ]
                    , button [ A.class "danger-button", Events.onClick (ConfirmDelete postId) ] [ text (Translations.deletePost active.texts) ]
                    ]
                ]

        Nothing ->
            text ""


viewFlash : Model -> Active -> Html Msg
viewFlash model active =
    case model.flash of
        NoFlash ->
            text ""

        flash ->
            div [ A.class "notice", A.attribute "role" "status", A.attribute "aria-live" "polite" ]
                [ p [] [ text (flashText active.texts flash) ]
                , button [ A.class "text-button", Events.onClick DismissFlash ] [ text (Translations.closeLabel active.texts) ]
                ]


viewLocaleNotice : Model -> Active -> Html Msg
viewLocaleNotice model active =
    let
        notice =
            model.loading.notice

        content =
            case notice of
                Localization.None ->
                    []

                Localization.Changed target ->
                    [ text (Translations.languageSwitchSuccess (Locale.label target) active.texts) ]

                Localization.Failed target ->
                    [ text (Translations.languageSwitchFailed (Locale.label target) active.texts) ]

                Localization.FallbackNotice target ->
                    [ text (Translations.languageFallbackNotice (Locale.label target) active.texts) ]
    in
    if List.isEmpty content then
        text ""

    else
        div [ A.class "notice", A.attribute "role" "status", A.attribute "aria-live" "polite" ]
            [ p [] content
            , case notice of
                Localization.Failed _ ->
                    button [ A.class "text-button", Events.onClick RetryLocalization ]
                        [ text (Translations.retryLabel active.texts) ]

                Localization.FallbackNotice _ ->
                    button [ A.class "text-button", Events.onClick RetryLocalization ]
                        [ text (Translations.retryLabel active.texts) ]

                _ ->
                    text ""
            ]


languageSelect : String -> (String -> Msg) -> Locale -> Html Msg
languageSelect identifier tagger selected =
    select
        [ A.id identifier
        , A.value (Locale.code selected)
        , Events.on "change" (Decode.map tagger (Decode.at [ "target", "value" ] Decode.string))
        ]
        (List.map
            (\locale ->
                option [ A.value (Locale.code locale), A.selected (locale == selected) ]
                    [ text (Locale.label locale) ]
            )
            Locale.all
        )


pendingIndicator : Model -> Active -> Html Msg
pendingIndicator model active =
    case Localization.pending model.loading of
        Just _ ->
            span [ A.class "pending-label", A.attribute "role" "status" ]
                [ text (Translations.loadingMessage active.texts) ]

        Nothing ->
            text ""

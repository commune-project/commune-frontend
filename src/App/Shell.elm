module App.Shell exposing (viewBoot, viewReady)

import App.Context exposing (Active)
import App.Feedback exposing (Flash(..), flashText)
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Feature.Auth.Update as Auth
import Generated.I18n as Translations
import Html exposing (Html, a, button, div, h1, h2, header, label, main_, nav, option, p, section, select, span, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import List
import Locale exposing (Locale(..))
import Localization
import Remote exposing (Remote(..))
import Route
import Ui.Formatting exposing (boolText, signedInLabel)


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
        [ a [ A.href "#main-content", A.class "skip-link" ] [ text (Translations.skipLink active.texts) ]
        , viewTopBar model active
        , viewLocaleNotice model active
        , viewFlash model active
        , main_ [ A.id "main-content", A.class "page-grid", A.tabindex -1 ]
            [ content ]
        , viewDrawer model active
        , viewConfirmation model active
        ]


viewTopBar : Model -> Active -> Html Msg
viewTopBar model active =
    header [ A.class "top-bar" ]
        [ button
            [ A.id "menu-button"
            , A.class "icon-button compact-menu"
            , A.attribute "aria-expanded" (boolText model.drawerOpen)
            , A.attribute "aria-controls" "navigation-drawer"
            , Events.onClick OpenDrawer
            ]
            [ span [ A.attribute "aria-hidden" "true" ] [ text "☰" ]
            , span [ A.class "sr-only" ] [ text (Translations.openMenu active.texts) ]
            ]
        , a [ A.href "/", A.class "brand" ] [ text (Translations.appTitle active.texts) ]
        , nav [ A.class "desktop-nav", A.attribute "aria-label" (Translations.mainNavigation active.texts) ]
            (navLinks model active [] True)
        , div [ A.class "language-control" ]
            [ case model.auth of
                Authenticated identity ->
                    span [ A.class "identity-label" ] [ text (signedInLabel active.texts identity) ]

                _ ->
                    text ""
            , label [ A.for "language-select" ] [ text (Translations.languageLabel active.texts) ]
            , languageSelect "language-select" LanguageSelected active.locale
            , pendingIndicator model active
            ]
        ]


navLinks : Model -> Active -> List (Html.Attribute Msg) -> Bool -> List (Html Msg)
navLinks model active extras includeAccount =
    let
        texts =
            active.texts

        notificationText =
            case model.notificationsPage.unreadCount of
                Just count ->
                    Translations.navNotifications texts ++ " (" ++ count ++ ")"

                Nothing ->
                    Translations.navNotifications texts

        account =
            case model.auth of
                Authenticated identity ->
                    [ a (A.href (Route.path (Route.Profile identity.username)) :: extras)
                        [ text (Translations.navProfile texts) ]
                    , a (A.href (Route.path Route.Settings) :: extras)
                        [ text (Translations.navSettings texts) ]
                    , button (A.class "link-button" :: Events.onClick (AuthMessage Auth.Logout) :: extras)
                        [ text (Translations.logout texts) ]
                    ]

                _ ->
                    [ a (A.href (Route.path Route.Login) :: extras)
                        [ text (Translations.navLogin texts) ]
                    ]
    in
    [ navLink model Route.Latest extras (Translations.navLatest texts)
    , navLink model Route.Communities extras (Translations.navCommunities texts)
    , navLink model Route.Search extras (Translations.navSearch texts)
    , navLink model Route.Notifications extras notificationText
    ]
        ++ (if includeAccount then
                account

            else
                []
           )


navLink : Model -> Route.Route -> List (Html.Attribute Msg) -> String -> Html Msg
navLink model target extras label =
    a
        (A.href (Route.path target)
            :: extras
            ++ (if model.route == target then
                    [ A.attribute "aria-current" "page" ]

                else
                    []
               )
        )
        [ text label ]


viewDrawer : Model -> Active -> Html Msg
viewDrawer model active =
    if model.drawerOpen then
        Html.node "dialog"
            [ A.id "navigation-drawer"
            , A.class "drawer"
            , A.attribute "aria-labelledby" "drawer-title"
            , Events.on "close" (Decode.succeed DrawerClosed)
            , Events.on "cancel" (Decode.succeed CloseDrawer)
            ]
            [ button [ A.class "icon-button drawer-close", Events.onClick CloseDrawer ]
                [ span [ A.attribute "aria-hidden" "true" ] [ text "×" ]
                , span [ A.class "sr-only" ] [ text (Translations.closeMenu active.texts) ]
                ]
            , h2 [ A.id "drawer-title" ] [ text (Translations.mainNavigation active.texts) ]
            , nav [ A.attribute "aria-label" (Translations.mainNavigation active.texts), A.class "drawer-nav" ]
                (navLinks model active [ Events.onClick CloseDrawer ] True)
            ]

    else
        text ""


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

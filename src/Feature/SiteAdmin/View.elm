module Feature.SiteAdmin.View exposing (Config, ViewModel, pageBans, pageModlog, pageOverview, pageReports, pageSettings)

import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Dict
import Domain
import Feature.SiteAdmin.State exposing (Model)
import Generated.I18n as Translations
import Html exposing (Html, a, button, div, form, h2, input, label, li, option, p, section, select, span, text, textarea, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import List
import Remote exposing (Remote(..))
import Route
import Set
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Formatting exposing (Formatting, boolText, formattedDate)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)


type alias Config msg =
    { retry : msg
    , upvotesChanged : Bool -> msg
    , downvotesChanged : Bool -> msg
    , saveSettings : msg
    , reportStateChanged : String -> msg
    , reportCommunityChanged : String -> msg
    , applyReportFilter : msg
    , reportNoteChanged : String -> String -> msg
    , confirmResolveReport : String -> String -> msg
    , modlogCommunityChanged : String -> msg
    , applyModlogFilter : msg
    , banActorChanged : String -> msg
    , banReasonChanged : String -> msg
    , banExpiresChanged : String -> msg
    , createBan : msg
    , confirmRemoveBan : msg
    }


type alias ViewModel =
    { admin : Model
    , auth : AuthState
    , formatted : Maybe Formatting
    , url : Url
    }


authorized : AuthState -> Bool
authorized auth =
    case auth of
        Authenticated identity ->
            identity.siteAdmin || identity.deploymentAdmin

        _ ->
            False


pageWrapper : ViewModel -> Active -> String -> Html msg -> Html msg
pageWrapper model active title content =
    case model.auth of
        Authenticated identity ->
            if identity.siteAdmin || identity.deploymentAdmin then
                pageHeading title
                    (section [ A.class "primary-column" ]
                        [ p [ A.class "muted" ] [ text (Translations.adminCurrentSiteHelp active.texts) ]
                        , adminNav active
                        , content
                        ]
                    )

            else
                pageHeading title (p [ A.class "card field-error", A.attribute "role" "alert" ] [ text (Translations.forbidden active.texts) ])

        _ ->
            pageHeading title (loginRequired active.texts)


adminNav : Active -> Html msg
adminNav active =
    navLinks
        [ ( Route.AdminOverview, Translations.adminOverview active.texts )
        , ( Route.AdminSettings, Translations.adminVoteSettings active.texts )
        , ( Route.AdminReports, Translations.adminReports active.texts )
        , ( Route.AdminModlog, Translations.adminModlog active.texts )
        , ( Route.AdminBans, Translations.adminBans active.texts )
        ]


navLinks : List ( Route.Route, String ) -> Html msg
navLinks items =
    div [ A.class "actions wrap" ]
        (List.map
            (\( route, labelText ) ->
                a [ A.class "outlined-button", A.href (Route.path route) ] [ text labelText ]
            )
            items
        )


pageOverview : Config msg -> ViewModel -> Active -> Html msg
pageOverview config model active =
    pageWrapper model
        active
        (Translations.adminTitle active.texts)
        (section [ A.class "card form-stack" ]
            [ h2 [] [ text (Translations.adminOverview active.texts) ]
            , p [] [ text (Translations.adminCurrentSiteHelp active.texts) ]
            , navLinks
                [ ( Route.Communities, Translations.communitiesTitle active.texts )
                , ( Route.AdminSettings, Translations.adminVoteSettings active.texts )
                , ( Route.AdminReports, Translations.adminReports active.texts )
                , ( Route.AdminModlog, Translations.adminModlog active.texts )
                , ( Route.AdminBans, Translations.adminBans active.texts )
                ]
            ]
        )


pageSettings : Config msg -> ViewModel -> Active -> Html msg
pageSettings config model active =
    pageWrapper model
        active
        (Translations.adminVoteSettings active.texts)
        (form [ Events.onSubmit config.saveSettings, A.class "card form-stack" ]
            [ h2 [] [ text (Translations.voteSettingsTitle active.texts) ]
            , p [ A.class "muted" ] [ text (Translations.voteSettingsHelp active.texts) ]
            , label []
                [ input
                    [ A.type_ "checkbox"
                    , A.checked model.admin.upvotesEnabled
                    , Events.onCheck config.upvotesChanged
                    ]
                    []
                , text (" " ++ Translations.upvotesEnabled active.texts)
                ]
            , label []
                [ input
                    [ A.type_ "checkbox"
                    , A.checked model.admin.downvotesEnabled
                    , Events.onCheck config.downvotesChanged
                    ]
                    []
                , text (" " ++ Translations.downvotesEnabled active.texts)
                ]
            , viewFormProblem active.texts model.admin.settingsProblem
            , button [ A.type_ "submit", A.class "filled-button", A.disabled model.admin.settingsBusy ]
                [ text (Translations.saveChanges active.texts) ]
            ]
        )


pageReports : Config msg -> ViewModel -> Active -> Html msg
pageReports config model active =
    pageWrapper model
        active
        (Translations.reportsTitle active.texts)
        (div [ A.class "stack" ]
            [ form [ Events.onSubmit config.applyReportFilter, A.class "card form-stack" ]
                [ h2 [] [ text (Translations.adminReports active.texts) ]
                , div []
                    [ label [ A.for "report-state" ] [ text (Translations.reportFilterState active.texts) ]
                    , select
                        [ A.id "report-state"
                        , Events.on "change" (Decode.map config.reportStateChanged (Decode.at [ "target", "value" ] Decode.string))
                        ]
                        [ option [ A.value "", A.selected (model.admin.reportState == "") ] [ text (Translations.allStates active.texts) ]
                        , option [ A.value "open", A.selected (model.admin.reportState == "open") ] [ text (Translations.stateOpen active.texts) ]
                        , option [ A.value "resolved", A.selected (model.admin.reportState == "resolved") ] [ text (Translations.stateResolved active.texts) ]
                        , option [ A.value "rejected", A.selected (model.admin.reportState == "rejected") ] [ text (Translations.stateRejected active.texts) ]
                        ]
                    ]
                , div []
                    [ label [ A.for "report-community" ] [ text (Translations.reportFilterCommunity active.texts) ]
                    , input
                        [ A.id "report-community"
                        , A.type_ "text"
                        , A.value model.admin.reportCommunity
                        , Events.onInput config.reportCommunityChanged
                        ]
                        []
                    ]
                , button [ A.type_ "submit", A.class "outlined-button" ] [ text (Translations.filter active.texts) ]
                ]
            , viewRemote config.retry
                active.texts
                model.admin.reports
                (reportsList config model active)
            ]
        )


reportsList : Config msg -> ViewModel -> Active -> Domain.Page Domain.Report -> Html msg
reportsList config model active page =
    if List.isEmpty page.items then
        p [ A.class "empty-state" ] [ text (Translations.noReports active.texts) ]

    else
        div [ A.class "stack" ]
            [ ul [ A.class "roster-list" ]
                (List.map
                    (\report ->
                        li [ A.class "card" ]
                            [ p [ A.class "chips" ]
                                [ span [ A.class "chip" ] [ text report.targetKind ]
                                , span [ A.class "chip" ] [ text (stateLabel active.texts report.state) ]
                                , span [ A.class "chip" ] [ text (formattedDate model.formatted report.createdAt) ]
                                ]
                            , p [ A.class "metadata" ] [ text (Translations.targetId active.texts ++ ": "), text report.targetId ]
                            , p [ A.dir "auto" ] [ text report.reason ]
                            , if report.state == "open" then
                                div [ A.class "form-stack" ]
                                    [ label [ A.for ("report-note-" ++ report.id) ] [ text (Translations.resolutionNote active.texts) ]
                                    , textarea
                                        [ A.id ("report-note-" ++ report.id)
                                        , A.value (Dict.get report.id model.admin.reportNotes |> Maybe.withDefault "")
                                        , Events.onInput (config.reportNoteChanged report.id)
                                        ]
                                        []
                                    , div [ A.class "actions" ]
                                        [ button
                                            [ A.id ("resolve-report-" ++ report.id)
                                            , A.type_ "button"
                                            , A.class "filled-button"
                                            , A.disabled (Set.member report.id model.admin.reportBusy)
                                            , Events.onClick (config.confirmResolveReport report.id "resolved")
                                            ]
                                            [ text (Translations.resolveReport active.texts) ]
                                        , button
                                            [ A.type_ "button"
                                            , A.class "outlined-button danger-text"
                                            , A.disabled (Set.member report.id model.admin.reportBusy)
                                            , Events.onClick (config.confirmResolveReport report.id "rejected")
                                            ]
                                            [ text (Translations.rejectReport active.texts) ]
                                        ]
                                    ]

                              else
                                p [ A.class "muted" ] [ text report.resolutionNote ]
                            ]
                    )
                    page.items
                )
            , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
            ]


pageModlog : Config msg -> ViewModel -> Active -> Html msg
pageModlog config model active =
    pageWrapper model
        active
        (Translations.modlogTitle active.texts)
        (div [ A.class "stack" ]
            [ form [ Events.onSubmit config.applyModlogFilter, A.class "card form-stack" ]
                [ label [ A.for "modlog-community" ] [ text (Translations.reportFilterCommunity active.texts) ]
                , input
                    [ A.id "modlog-community"
                    , A.type_ "text"
                    , A.value model.admin.modlogCommunity
                    , Events.onInput config.modlogCommunityChanged
                    ]
                    []
                , button [ A.type_ "submit", A.class "outlined-button" ] [ text (Translations.filter active.texts) ]
                ]
            , viewRemote config.retry active.texts model.admin.modlog (modlogList model active)
            ]
        )


modlogList : ViewModel -> Active -> Domain.Page Domain.ModerationLogEntry -> Html msg
modlogList model active page =
    if List.isEmpty page.items then
        p [ A.class "empty-state" ] [ text (Translations.noModlog active.texts) ]

    else
        div [ A.class "stack" ]
            [ ul [ A.class "roster-list" ]
                (List.map
                    (\entry ->
                        li [ A.class "card" ]
                            [ p [ A.class "chips" ]
                                [ span [ A.class "chip" ] [ text entry.action ]
                                , span [ A.class "chip" ] [ text (formattedDate model.formatted entry.createdAt) ]
                                ]
                            , p [ A.class "metadata" ]
                                [ text (Translations.actingActor active.texts ++ ": ")
                                , text entry.actorActorUri
                                ]
                            , p [ A.class "metadata" ]
                                [ text (Translations.targetKind active.texts ++ ": ")
                                , text entry.targetKind
                                , text " · "
                                , text (Translations.targetId active.texts ++ ": ")
                                , text entry.targetId
                                ]
                            , if String.isEmpty entry.reason then
                                text ""

                              else
                                p [ A.dir "auto" ] [ text entry.reason ]
                            ]
                    )
                    page.items
                )
            , viewPagination active.texts model.url page.offset page.limit (List.length page.items)
            ]


pageBans : Config msg -> ViewModel -> Active -> Html msg
pageBans config model active =
    pageWrapper model
        active
        (Translations.banTitle active.texts)
        (form [ Events.onSubmit config.createBan, A.class "card form-stack" ]
            [ h2 [] [ text (Translations.banTitle active.texts) ]
            , p [ A.class "muted" ] [ text (Translations.banNoInventory active.texts) ]
            , div []
                [ label [ A.for "ban-actor" ] [ text (Translations.banActor active.texts) ]
                , input
                    [ A.id "ban-actor"
                    , A.type_ "text"
                    , A.value model.admin.banActor
                    , Events.onInput config.banActorChanged
                    ]
                    []
                ]
            , div []
                [ label [ A.for "ban-reason" ] [ text (Translations.banReason active.texts) ]
                , textarea
                    [ A.id "ban-reason"
                    , A.value model.admin.banReason
                    , Events.onInput config.banReasonChanged
                    ]
                    []
                ]
            , div []
                [ label [ A.for "ban-expires" ] [ text (Translations.banExpires active.texts) ]
                , input
                    [ A.id "ban-expires"
                    , A.type_ "text"
                    , A.placeholder "2026-11-01T12:00:00Z"
                    , A.value model.admin.banExpires
                    , Events.onInput config.banExpiresChanged
                    ]
                    []
                , p [ A.class "muted" ] [ text (Translations.optional active.texts) ]
                ]
            , case model.admin.banProblem of
                Just problem ->
                    p [ A.class "field-error", A.attribute "role" "alert" ]
                        [ text
                            (if problem.status == 404 then
                                Translations.banNotActive active.texts

                             else
                                Ui.Feedback.problemText active.texts problem
                            )
                        ]

                Nothing ->
                    text ""
            , div [ A.class "actions" ]
                [ button [ A.type_ "submit", A.class "filled-button", A.disabled model.admin.banBusy ]
                    [ text (Translations.createBan active.texts) ]
                , button [ A.id "site-ban-remove", A.type_ "button", A.class "outlined-button danger-text", A.disabled model.admin.banBusy, Events.onClick config.confirmRemoveBan ]
                    [ text (Translations.removeBan active.texts) ]
                ]
            ]
        )


stateLabel : Translations.I18n -> String -> String
stateLabel texts state =
    case state of
        "open" ->
            Translations.stateOpen texts

        "resolved" ->
            Translations.stateResolved texts

        "rejected" ->
            Translations.stateRejected texts

        _ ->
            state

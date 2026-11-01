module Feature.CommunityManage.View exposing (Config, pageManage)

import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Dict
import Domain
import Feature.CommunityManage.State exposing (..)
import Generated.I18n as Translations
import Html exposing (Html, a, bdi, button, div, form, h2, input, label, li, option, p, section, select, span, text, textarea, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode
import List
import Remote exposing (Remote(..))
import Route
import Ui.CommunityPolicy exposing (policyFields)
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Formatting exposing (modeLabel, policyLabel)
import Ui.Layout exposing (pageHeading)


type alias Config msg =
    { retry : msg
    , manageActorChanged : String -> msg
    , managePostChanged : String -> msg
    , manageContextChanged : String -> msg
    , manageReadChanged : String -> msg
    , managePostPolicyChanged : String -> msg
    , manageFollowPolicyChanged : String -> msg
    , manageApplyPolicy : msg
    , manageAddMember : msg
    , manageRemoveMember : String -> msg
    , manageAddManager : msg
    , manageRemoveManager : String -> msg
    , managePreviousMembers : msg
    , manageNextMembers : msg
    , managePreviousManagers : msg
    , manageNextManagers : msg
    , managePreviousFollowRequests : msg
    , manageNextFollowRequests : msg
    , managePreviousReports : msg
    , manageNextReports : msg
    , managePreviousModlog : msg
    , manageNextModlog : msg
    , managePostAction : String -> ManagePostAction -> msg
    , manageFollowDecision : String -> String -> msg
    , manageReportNoteChanged : String -> String -> msg
    , manageConfirmResolveReport : String -> String -> msg
    , manageBanActorChanged : String -> msg
    , manageBanReasonChanged : String -> msg
    , manageBanExpiresChanged : String -> msg
    , manageCreateBan : msg
    , manageConfirmRemoveBan : msg
    }


type alias ViewModel =
    { auth : AuthState, manage : Maybe ManageState }


pageManage : Config msg -> ViewModel -> Active -> String -> Html msg
pageManage config model active communityIdValue =
    pageHeading (Translations.manageTitle active.texts)
        (case ( model.auth, model.manage ) of
            ( Authenticated _, Just manage ) ->
                section [ A.class "primary-column" ]
                    [ viewRemote config.retry active.texts manage.community (communitySection active)
                    , case model.auth of
                        Authenticated identity ->
                            if identity.siteAdmin || identity.deploymentAdmin then
                                a [ A.class "outlined-button", A.href (Route.path Route.AdminOverview) ]
                                    [ text (Translations.adminTitle active.texts) ]

                            else
                                text ""

                        _ ->
                            text ""
                    , if canManageCommunity manage then
                        managePolicy config active manage

                      else
                        text ""
                    , manageRosters config active manage
                    , manageFollowRequests config active manage
                    , manageReports config active manage
                    , manageModlog config active manage
                    , manageBans config active manage
                    , managePostActions config model active manage
                    ]

            _ ->
                loginRequired active.texts
        )


communitySection : Active -> Domain.Community -> Html msg
communitySection active community =
    section [ A.class "card" ]
        [ h2 [] [ text community.title ]
        , p [ A.class "metadata" ]
            [ text
                (Translations.policySummary
                    { read = policyLabel active.texts community.readPolicy
                    , post = policyLabel active.texts community.postPolicy
                    }
                    active.texts
                )
            ]
        , p [ A.class "chips" ] [ span [ A.class "chip" ] [ text (modeLabel active.texts community.mode) ] ]
        ]


managePolicy : Config msg -> Active -> ManageState -> Html msg
managePolicy config active manage =
    form [ Events.onSubmit config.manageApplyPolicy, A.class "card form-stack" ]
        [ h2 [] [ text (Translations.readPolicy active.texts) ]
        , policyFields active manage.readPolicy manage.postPolicy config.manageReadChanged config.managePostPolicyChanged
        , div []
            [ label [ A.for "manage-follow-policy" ] [ text (Translations.followPolicy active.texts) ]
            , select
                [ A.id "manage-follow-policy"
                , Events.on "change" (Json.Decode.map config.manageFollowPolicyChanged (Json.Decode.at [ "target", "value" ] Json.Decode.string))
                ]
                [ option [ A.value "open", A.selected (manage.followPolicy == "open") ] [ text (Translations.followPolicyOpen active.texts) ]
                , option [ A.value "members", A.selected (manage.followPolicy == "members") ] [ text (Translations.followPolicyMembers active.texts) ]
                , option [ A.value "approval", A.selected (manage.followPolicy == "approval") ] [ text (Translations.followPolicyApproval active.texts) ]
                , option [ A.value "disabled", A.selected (manage.followPolicy == "disabled") ] [ text (Translations.followPolicyDisabled active.texts) ]
                ]
            ]
        , button [ A.type_ "submit", A.class "filled-button" ] [ text (Translations.saveChanges active.texts) ]
        ]


manageRosters : Config msg -> Active -> ManageState -> Html msg
manageRosters config active manage =
    let
        canMembers =
            canManageMembers manage

        canManagers =
            canManageManagers manage
    in
    section [ A.class "stack" ]
        [ if canMembers || canManagers then
            div [ A.class "card form-stack" ]
                [ label [ A.for "manage-actor" ] [ text (Translations.actorUri active.texts) ]
                , input [ A.id "manage-actor", A.type_ "text", A.value manage.actor, Events.onInput config.manageActorChanged ]
                    []
                , div [ A.class "actions" ]
                    [ if canMembers then
                        button [ A.type_ "button", A.class "outlined-button", Events.onClick config.manageAddMember ]
                            [ text (Translations.addMember active.texts) ]

                      else
                        text ""
                    , if canManagers then
                        button [ A.type_ "button", A.class "outlined-button", Events.onClick config.manageAddManager ]
                            [ text (Translations.addManager active.texts) ]

                      else
                        text ""
                    ]
                ]

          else
            text ""
        , rosterPanel config active (Translations.memberRoster active.texts) manage.members True canMembers manage.memberOffset config.managePreviousMembers config.manageNextMembers
        , rosterPanel config active (Translations.managerRoster active.texts) manage.managers False canManagers manage.managerOffset config.managePreviousManagers config.manageNextManagers
        ]


rosterPanel :
    Config msg
    -> Active
    -> String
    -> Remote (Domain.Page Domain.Roster)
    -> Bool
    -> Bool
    -> Int
    -> msg
    -> msg
    -> Html msg
rosterPanel config active title remote members canRemove offset onPrevious onNext =
    section [ A.class "card" ]
        [ h2 [] [ text title ]
        , viewRemote config.retry
            active.texts
            remote
            (\page ->
                if List.isEmpty page.items then
                    p [ A.class "muted" ] [ text (Translations.noRosterEntries active.texts) ]

                else
                    ul [ A.class "roster-list" ]
                        (List.map
                            (\entry ->
                                li []
                                    [ bdi [] [ text entry.actor ]
                                    , span [ A.class "chips" ]
                                        [ if entry.creator then
                                            span [ A.class "chip" ] [ text (Translations.createCommunity active.texts) ]

                                          else
                                            text ""
                                        , if canRemove && not entry.creator then
                                            button
                                                [ A.type_ "button"
                                                , A.class "text-button danger-text"
                                                , Events.onClick
                                                    (if members then
                                                        config.manageRemoveMember entry.actor

                                                     else
                                                        config.manageRemoveManager entry.actor
                                                    )
                                                ]
                                                [ text
                                                    (if members then
                                                        Translations.removeMember active.texts

                                                     else
                                                        Translations.removeManager active.texts
                                                    )
                                                ]

                                          else
                                            text ""
                                        ]
                                    ]
                            )
                            page.items
                        )
                        |> (\rows ->
                                div [ A.class "stack" ]
                                    [ rows
                                    , div [ A.class "pagination" ]
                                        [ button [ A.type_ "button", A.class "outlined-button", A.disabled (offset <= 0), Events.onClick onPrevious ]
                                            [ text (Translations.previousPage active.texts) ]
                                        , if List.length page.items >= page.limit then
                                            button [ A.type_ "button", A.class "outlined-button", Events.onClick onNext ]
                                                [ text (Translations.nextPage active.texts) ]

                                          else
                                            text ""
                                        ]
                                    ]
                           )
            )
        ]


manageFollowRequests : Config msg -> Active -> ManageState -> Html msg
manageFollowRequests config active manage =
    if not (canManageCommunity manage) then
        text ""

    else
        section [ A.class "card" ]
            [ h2 [] [ text (Translations.followRequests active.texts) ]
            , viewRemote config.retry
                active.texts
                manage.followRequests
                (\page ->
                    if List.isEmpty page.items then
                        p [ A.class "muted" ] [ text (Translations.noFollowRequests active.texts) ]

                    else
                        div [ A.class "stack" ]
                            [ ul [ A.class "roster-list" ]
                                (List.map
                                    (\request ->
                                        li []
                                            [ bdi [] [ text request.actor ]
                                            , span [ A.class "actions" ]
                                                [ button
                                                    [ A.type_ "button"
                                                    , A.class "text-button"
                                                    , Events.onClick (config.manageFollowDecision request.actor "accepted")
                                                    ]
                                                    [ text (Translations.accept active.texts) ]
                                                , button
                                                    [ A.type_ "button"
                                                    , A.class "text-button danger-text"
                                                    , Events.onClick (config.manageFollowDecision request.actor "rejected")
                                                    ]
                                                    [ text (Translations.reject active.texts) ]
                                                ]
                                            ]
                                    )
                                    page.items
                                )
                            , pager active page manage.followRequestOffset config.managePreviousFollowRequests config.manageNextFollowRequests
                            ]
                )
            ]


manageReports : Config msg -> Active -> ManageState -> Html msg
manageReports config active manage =
    if not (canManageCommunity manage) then
        text ""

    else
        section [ A.class "card" ]
            [ h2 [] [ text (Translations.reportsTitle active.texts) ]
            , viewRemote config.retry
                active.texts
                manage.reports
                (\page ->
                    if List.isEmpty page.items then
                        p [ A.class "muted" ] [ text (Translations.noReports active.texts) ]

                    else
                        div [ A.class "stack" ]
                            [ ul [ A.class "roster-list" ]
                                (List.map
                                    (\report ->
                                        li []
                                            [ p [ A.class "chips" ]
                                                [ span [ A.class "chip" ] [ text report.targetKind ]
                                                , span [ A.class "chip" ] [ text report.state ]
                                                ]
                                            , p [ A.dir "auto" ] [ text report.reason ]
                                            , if report.state == "open" then
                                                div [ A.class "form-stack" ]
                                                    [ label [ A.for ("community-report-note-" ++ report.id) ] [ text (Translations.resolutionNote active.texts) ]
                                                    , textarea
                                                        [ A.id ("community-report-note-" ++ report.id)
                                                        , A.value (Dict.get report.id manage.reportNotes |> Maybe.withDefault "")
                                                        , Events.onInput (config.manageReportNoteChanged report.id)
                                                        ]
                                                        []
                                                    , div [ A.class "actions" ]
                                                        [ button
                                                            [ A.id ("resolve-report-" ++ report.id)
                                                            , A.type_ "button"
                                                            , A.class "filled-button"
                                                            , Events.onClick (config.manageConfirmResolveReport report.id "resolved")
                                                            ]
                                                            [ text (Translations.resolveReport active.texts) ]
                                                        , button
                                                            [ A.type_ "button"
                                                            , A.class "outlined-button danger-text"
                                                            , Events.onClick (config.manageConfirmResolveReport report.id "rejected")
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
                            , pager active page manage.reportOffset config.managePreviousReports config.manageNextReports
                            ]
                )
            ]


manageModlog : Config msg -> Active -> ManageState -> Html msg
manageModlog config active manage =
    if not (canManageCommunity manage) then
        text ""

    else
        section [ A.class "card" ]
            [ h2 [] [ text (Translations.modlogTitle active.texts) ]
            , viewRemote config.retry
                active.texts
                manage.modlog
                (\page ->
                    if List.isEmpty page.items then
                        p [ A.class "muted" ] [ text (Translations.noModlog active.texts) ]

                    else
                        div [ A.class "stack" ]
                            [ ul [ A.class "roster-list" ]
                                (List.map
                                    (\entry ->
                                        li []
                                            [ p [ A.class "chips" ]
                                                [ span [ A.class "chip" ] [ text entry.action ]
                                                ]
                                            , p [ A.class "metadata" ] [ bdi [] [ text entry.actorActorUri ] ]
                                            , p [ A.class "metadata" ] [ text (entry.targetKind ++ ": " ++ entry.targetId) ]
                                            , if String.isEmpty entry.reason then
                                                text ""

                                              else
                                                p [ A.dir "auto" ] [ text entry.reason ]
                                            ]
                                    )
                                    page.items
                                )
                            , pager active page manage.modlogOffset config.managePreviousModlog config.manageNextModlog
                            ]
                )
            ]


pager : Active -> Domain.Page a -> Int -> msg -> msg -> Html msg
pager active page offset onPrevious onNext =
    div [ A.class "pagination" ]
        [ button [ A.type_ "button", A.class "outlined-button", A.disabled (offset <= 0), Events.onClick onPrevious ]
            [ text (Translations.previousPage active.texts) ]
        , if List.length page.items >= page.limit then
            button [ A.type_ "button", A.class "outlined-button", Events.onClick onNext ]
                [ text (Translations.nextPage active.texts) ]

          else
            text ""
        ]


manageBans : Config msg -> Active -> ManageState -> Html msg
manageBans config active manage =
    if not (canManageCommunity manage) then
        text ""

    else
        form [ Events.onSubmit config.manageCreateBan, A.class "card form-stack" ]
            [ h2 [] [ text (Translations.communityBanTitle active.texts) ]
            , p [ A.class "muted" ] [ text (Translations.communityBanHelp active.texts) ]
            , div []
                [ label [ A.for "community-ban-actor" ] [ text (Translations.banActor active.texts) ]
                , input
                    [ A.id "community-ban-actor"
                    , A.type_ "text"
                    , A.value manage.banActor
                    , Events.onInput config.manageBanActorChanged
                    ]
                    []
                ]
            , div []
                [ label [ A.for "community-ban-reason" ] [ text (Translations.banReason active.texts) ]
                , textarea
                    [ A.id "community-ban-reason"
                    , A.value manage.banReason
                    , Events.onInput config.manageBanReasonChanged
                    ]
                    []
                ]
            , div []
                [ label [ A.for "community-ban-expires" ] [ text (Translations.banExpires active.texts) ]
                , input
                    [ A.id "community-ban-expires"
                    , A.type_ "text"
                    , A.placeholder "2026-11-01T12:00:00Z"
                    , A.value manage.banExpires
                    , Events.onInput config.manageBanExpiresChanged
                    ]
                    []
                ]
            , viewFormProblem active.texts manage.banProblem
            , div [ A.class "actions" ]
                [ button [ A.type_ "submit", A.class "filled-button" ] [ text (Translations.createBan active.texts) ]
                , button [ A.id "community-ban-remove", A.type_ "button", A.class "outlined-button danger-text", Events.onClick config.manageConfirmRemoveBan ]
                    [ text (Translations.removeBan active.texts) ]
                ]
            ]


managePostActions : Config msg -> ViewModel -> Active -> ManageState -> Html msg
managePostActions config model active manage =
    let
        moderate =
            canManageCommunity manage

        siteAdmin =
            case model.auth of
                Authenticated identity ->
                    identity.siteAdmin || identity.deploymentAdmin

                _ ->
                    False

        canBackfill =
            case manage.community of
                Ready community ->
                    community.canPost

                _ ->
                    False
    in
    section [ A.class "card form-stack" ]
        [ h2 [] [ text (Translations.postId active.texts) ]
        , label [ A.for "manage-post-id" ] [ text (Translations.postId active.texts) ]
        , input [ A.id "manage-post-id", A.type_ "text", A.value manage.postId, Events.onInput config.managePostChanged ] []
        , div [ A.class "actions wrap" ]
            [ if moderate then
                managePostButton config active "remove" RemoveCommunityPost manage.postId

              else
                text ""
            , if moderate then
                managePostButton config active "restore" RestoreCommunityPost manage.postId

              else
                text ""
            , if siteAdmin then
                managePostButton config active "hide" HideSitePost manage.postId

              else
                text ""
            , if siteAdmin then
                managePostButton config active "unhide" UnhideSitePost manage.postId

              else
                text ""
            , managePostButton config active "import" ImportSitePost manage.postId
            , if moderate then
                managePostButton config active "accept" AcceptSubmission manage.postId

              else
                text ""
            , if moderate then
                managePostButton config active "reject" RejectSubmission manage.postId

              else
                text ""
            ]
        , if canBackfill then
            div [ A.class "form-stack" ]
                [ label [ A.for "manage-context-id" ] [ text (Translations.contextId active.texts) ]
                , input [ A.id "manage-context-id", A.type_ "text", A.value manage.contextId, Events.onInput config.manageContextChanged ] []
                , managePostButton config active "backfill" BackfillDiscussion manage.contextId
                ]

          else
            text ""
        , viewFormProblem active.texts manage.problem
        ]


managePostButton : Config msg -> Active -> String -> ManagePostAction -> String -> Html msg
managePostButton config active _ action id =
    button
        [ A.type_ "button"
        , A.class "outlined-button"
        , A.disabled (String.isEmpty (String.trim id))
        , Events.onClick (config.managePostAction id action)
        ]
        [ text (manageActionLabel active.texts action) ]


manageActionLabel : Translations.I18n -> ManagePostAction -> String
manageActionLabel texts action =
    case action of
        RemoveCommunityPost ->
            Translations.removePostFromCommunity texts

        RestoreCommunityPost ->
            Translations.restorePostToCommunity texts

        HideSitePost ->
            Translations.hidePost texts

        UnhideSitePost ->
            Translations.unhidePost texts

        ImportSitePost ->
            Translations.importPost texts

        AcceptSubmission ->
            Translations.acceptSubmission texts

        RejectSubmission ->
            Translations.rejectSubmission texts

        BackfillDiscussion ->
            Translations.backfillContext texts


canManageCommunity : ManageState -> Bool
canManageCommunity manage =
    case manage.community of
        Ready community ->
            community.canManage

        _ ->
            False


canManageMembers : ManageState -> Bool
canManageMembers manage =
    case manage.community of
        Ready community ->
            community.canMembers

        _ ->
            False


canManageManagers : ManageState -> Bool
canManageManagers manage =
    case manage.community of
        Ready community ->
            community.canManagers

        _ ->
            False

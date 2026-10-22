module Feature.CommunityManage.View exposing (Config, pageManage)

import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Domain
import Feature.CommunityManage.State exposing (..)
import Generated.I18n as Translations
import Html exposing (Html, bdi, button, div, form, h2, input, label, li, p, section, span, text, ul)
import Html.Attributes as A
import Html.Events as Events
import List
import Remote exposing (Remote(..))
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
    , manageApplyPolicy : msg
    , manageAddMember : msg
    , manageRemoveMember : String -> msg
    , manageAddManager : msg
    , manageRemoveManager : String -> msg
    , managePreviousMembers : msg
    , manageNextMembers : msg
    , managePreviousManagers : msg
    , manageNextManagers : msg
    , managePostAction : String -> ManagePostAction -> msg
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
                    , if canManageCommunity manage then
                        managePolicy config active manage

                      else
                        text ""
                    , manageRosters config active manage
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

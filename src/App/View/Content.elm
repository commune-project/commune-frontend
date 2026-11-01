module App.View.Content exposing (editorConfig, pageCommunities, pageCommunity, pageLatest, pagePost, pageSearch, postCard)

import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import App.State exposing (Model, Msg(..))
import Domain
import Feature.Community as Community
import Feature.Editor.State exposing (EditorMode(..))
import Feature.Editor.Update as Editor
import Feature.Editor.View
import Feature.Feed as Feed
import Feature.Post as Post
import Feature.Report as Report
import Feature.Search as Search
import Generated.I18n as Translations
import Html exposing (Html, a, text)
import Html.Attributes as A
import List
import Route
import Set exposing (Set)
import Ui.PostCard


postCard : Model -> Active -> Domain.Post -> Html Msg
postCard model active =
    Ui.PostCard.postCard
        { formatted = model.formatted
        , isBusy = \id -> Post.isBusy id model.posts.busy
        , isExpanded = \id -> Set.member id model.posts.expandedReplies
        , onLike = \id liked -> PostMessage (Post.ToggleLike id liked)
        , onDownvote = \id score -> PostMessage (Post.Vote id score)
        , onSave = \id saved -> PostMessage (Post.ToggleSave id saved)
        , onHideForMe = \id hidden -> PostMessage (Post.ToggleHideForMe id hidden)
        , onReport = \id community -> ReportMessage (Report.Open (Report.PostTarget id community))
        , canReport =
            case model.auth of
                Authenticated _ ->
                    True

                _ ->
                    False
        , onDelete = OpenDeleteDialog
        , onReplies = PostMessage << Post.ToggleReplies
        , nested = \id -> viewNested active id model
        }
        active.texts


threadedPostCard : Model -> Active -> Domain.Post -> Html Msg -> Html Msg
threadedPostCard model active post nested =
    Ui.PostCard.postCard
        { formatted = model.formatted
        , isBusy = \id -> Post.isBusy id model.posts.busy
        , isExpanded = always True
        , onLike = \id liked -> PostMessage (Post.ToggleLike id liked)
        , onDownvote = \id score -> PostMessage (Post.Vote id score)
        , onSave = \id saved -> PostMessage (Post.ToggleSave id saved)
        , onHideForMe = \id hidden -> PostMessage (Post.ToggleHideForMe id hidden)
        , onReport = \id community -> ReportMessage (Report.Open (Report.PostTarget id community))
        , canReport =
            case model.auth of
                Authenticated _ ->
                    True

                _ ->
                    False
        , onDelete = OpenDeleteDialog
        , onReplies = PostMessage << Post.ToggleReplies
        , nested = always nested
        }
        active.texts
        post


editorConfig : Model -> Feature.Editor.View.Config Msg
editorConfig model =
    { auth = model.auth
    , retry = RetryPage
    , editorTitleChanged = EditorMessage << Editor.EditorTitleChanged
    , editorBodyChanged = EditorMessage << Editor.EditorBodyChanged
    , editorFormatChanged = EditorMessage << Editor.EditorFormatChanged
    , editorRemoveAttachment = EditorMessage << Editor.EditorRemoveAttachment
    , editorFileSelected = EditorMessage << Editor.EditorFileSelected
    , editorSubmit = EditorMessage Editor.EditorSubmit
    , editorUseLatest = EditorMessage Editor.EditorUseLatest
    , editorKeepDraft = EditorMessage Editor.EditorKeepDraft
    }


pageSearch : Model -> Active -> Html Msg
pageSearch model active =
    Search.pageSearch (searchViewConfig model active) { search = model.searchPage.search, url = model.url } active


searchViewConfig : Model -> Active -> Search.Config Msg
searchViewConfig model active =
    { retry = RetryPage
    , searchKindChanged = SearchMessage << Search.SearchKindChanged
    , searchQueryChanged = SearchMessage << Search.SearchQueryChanged
    , searchSubmitted = SearchMessage Search.SearchSubmitted
    , postCard = postCard model active
    }


pagePost : Model -> Active -> String -> Html Msg
pagePost model active postId =
    Post.pagePost (postViewConfig model active) { post = model.posts.post, replies = model.posts.replies, url = model.url } active postId


viewNested : Active -> String -> Model -> Html Msg
viewNested active parent _ =
    a [ A.class "outlined-button", A.href (Route.path (Route.Post parent)) ]
        [ text (Translations.repliesTitle active.texts) ]


postViewConfig : Model -> Active -> Post.Config Msg
postViewConfig model active =
    { retry = RetryPage
    , postCard = postCard model active
    , threadedPostCard = threadedPostCard model active
    , startReply = EditorMessage << Editor.StartReply
    , editor =
        case model.editorPage.editor of
            Just editor ->
                case editor.mode of
                    CreateReply _ ->
                        Feature.Editor.View.viewEditor (editorConfig model) active editor

                    _ ->
                        text ""

            Nothing ->
                text ""
    , sort =
        Route.query "sort" model.url
            |> (\value ->
                    if List.member value [ "new", "old", "top", "controversial" ] then
                        value

                    else
                        "old"
               )
    , maxDepth =
        Route.query "max_depth" model.url
            |> String.toInt
            |> Maybe.withDefault 6
            |> clamp 1 8
    , sortChanged = PostMessage << Post.SortChanged
    , depthChanged = PostMessage << Post.DepthChanged
    , isExpanded = \id -> Set.member id model.posts.expandedReplies
    , onReplies = PostMessage << Post.ToggleReplies
    }


pageLatest : Model -> Active -> Html Msg
pageLatest model active =
    Feed.pageLatest (feedViewConfig model active) { topics = model.feed.topics, url = model.url } active


feedViewConfig : Model -> Active -> Feed.Config Msg
feedViewConfig model active =
    { retry = RetryPage
    , postCard = postCard model active
    }


pageCommunities : Model -> Active -> Html Msg
pageCommunities model active =
    Community.pageCommunities (communityViewConfig model active) (communityViewModel model) active


pageCommunity : Model -> Active -> String -> Html Msg
pageCommunity model active id =
    Community.pageCommunity (communityViewConfig model active) (communityViewModel model) active id


communityViewConfig : Model -> Active -> Community.Config Msg
communityViewConfig model active =
    { retry = RetryPage
    , postCard = postCard model active
    , toggleFollow = CommunityMessage << Community.ToggleFollow
    , reportCommunity = \id -> ReportMessage (Report.Open (Report.CommunityTarget id))
    }


communityViewModel : Model -> Community.ViewModel
communityViewModel model =
    { communities = model.communityPage.communities
    , community = model.communityPage.community
    , communityTopics = model.communityPage.communityTopics
    , busy = model.communityPage.busy
    , problem = model.communityPage.problem
    , auth = model.auth
    , url = model.url
    }

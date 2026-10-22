module App.View.Content exposing (editorConfig, pageCommunities, pageCommunity, pageLatest, pagePost, pageSearch)

import App.Context exposing (Active)
import App.State exposing (Model, Msg(..))
import Domain
import Feature.Community as Community
import Feature.Editor.State exposing (EditorMode(..))
import Feature.Editor.Update as Editor
import Feature.Editor.View
import Feature.Feed as Feed
import Feature.Post as Post exposing (likeKey)
import Feature.Search as Search
import Html exposing (Html, text)
import Set exposing (Set)
import Ui.PostCard


postCard : Model -> Active -> Domain.Post -> Html Msg
postCard model active =
    Ui.PostCard.postCard
        { formatted = model.formatted
        , isBusy = \id -> Set.member (likeKey id) model.posts.busy
        , isExpanded = \id -> Set.member id model.posts.expandedReplies
        , onLike = \id liked -> PostMessage (Post.ToggleLike id liked)
        , onDelete = OpenDeleteDialog
        , onReplies = PostMessage << Post.ToggleReplies
        , nested = \id -> viewNested active id model
        }
        active.texts


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
    Post.pagePost (postViewConfig model active) { post = model.posts.post, replies = model.posts.replies, nestedReplies = model.posts.nestedReplies, url = model.url } active postId


viewNested : Active -> String -> Model -> Html Msg
viewNested active parent model =
    Post.viewNested (postViewConfig model active) active parent { post = model.posts.post, replies = model.posts.replies, nestedReplies = model.posts.nestedReplies, url = model.url }


postViewConfig : Model -> Active -> Post.Config Msg
postViewConfig model active =
    { retry = RetryPage
    , postCard = postCard model active
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
    Community.pageCommunities (communityViewConfig model active) { communities = model.communityPage.communities, community = model.communityPage.community, communityTopics = model.communityPage.communityTopics, url = model.url } active


pageCommunity : Model -> Active -> String -> Html Msg
pageCommunity model active id =
    Community.pageCommunity (communityViewConfig model active) { communities = model.communityPage.communities, community = model.communityPage.community, communityTopics = model.communityPage.communityTopics, url = model.url } active id


communityViewConfig : Model -> Active -> Community.Config Msg
communityViewConfig model active =
    { retry = RetryPage
    , postCard = postCard model active
    }

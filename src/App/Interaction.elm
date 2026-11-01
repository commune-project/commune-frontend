module App.Interaction exposing (applyPost)

import App.State exposing (Model)
import Domain
import Feature.Search as Search exposing (SearchResult(..))
import List
import Remote exposing (Remote(..))


applyPost : Domain.Post -> Model -> Model
applyPost post model =
    let
        transform candidate =
            if candidate.id == post.id then
                post

            else
                candidate

        page remote =
            Remote.map (\data -> { data | items = List.map transform data.items }) remote

        threaded (Domain.ThreadedPost node) =
            Domain.ThreadedPost
                { node
                    | post = transform node.post
                    , children = List.map threaded node.children
                }

        threadedPage remote =
            Remote.map (\data -> { data | items = List.map threaded data.items }) remote

        searchState =
            model.searchPage.search
    in
    { model
        | posts =
            (\postsState ->
                { postsState
                    | post = Remote.map transform model.posts.post
                    , replies = threadedPage model.posts.replies
                }
            )
                model.posts
        , feed = (\feedState -> { feedState | topics = page model.feed.topics }) model.feed
        , communityPage = (\communityPageState -> { communityPageState | communityTopics = page model.communityPage.communityTopics }) model.communityPage
        , accountContent = (\state -> { state | posts = page model.accountContent.posts }) model.accountContent
        , searchPage =
            (\searchPageState ->
                { searchPageState
                    | search =
                        case model.searchPage.search.results of
                            Ready (PostSearch data) ->
                                { searchState | results = Ready (PostSearch { data | items = List.map transform data.items }) }

                            _ ->
                                model.searchPage.search
                }
            )
                model.searchPage
    }

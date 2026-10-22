module App.Interaction exposing (applyLike)

import App.State exposing (Model)
import Dict exposing (Dict)
import Feature.Search as Search exposing (SearchResult(..))
import List
import Remote exposing (Remote(..))


applyLike : String -> Bool -> Model -> Model
applyLike id wasLiked model =
    let
        transform post =
            if post.id == id then
                { post
                    | liked = not wasLiked
                    , likes =
                        max 0
                            (post.likes
                                + (if wasLiked then
                                    -1

                                   else
                                    1
                                  )
                            )
                }

            else
                post

        page remote =
            Remote.map (\data -> { data | items = List.map transform data.items }) remote

        searchState =
            model.searchPage.search
    in
    { model
        | posts = (\postsState -> { postsState | post = Remote.map transform model.posts.post, replies = page model.posts.replies, nestedReplies = Dict.map (\_ value -> page value) model.posts.nestedReplies }) model.posts
        , feed = (\feedState -> { feedState | topics = page model.feed.topics }) model.feed
        , communityPage = (\communityPageState -> { communityPageState | communityTopics = page model.communityPage.communityTopics }) model.communityPage
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

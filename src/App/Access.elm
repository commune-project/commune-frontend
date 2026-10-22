module App.Access exposing (authProblem, clearPrivate)

import Api
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import App.State exposing (Model)
import Feature.CommunityManage.State as ManageState
import Feature.Notifications as Notifications
import Feature.Profile as Profile
import Set exposing (Set)


authProblem : Model -> Api.Problem -> Model
authProblem model problem =
    if problem.status == 401 then
        clearPrivate
            { model | auth = Anonymous, authGeneration = model.authGeneration + 1, csrf = "", flash = FlashProblem problem }

    else
        model


clearPrivate : Model -> Model
clearPrivate model =
    { model
        | profile = Profile.clearPrivate model.profile
        , notificationsPage = Notifications.initial
        , management = ManageState.initial
        , posts = (\postsState -> { postsState | busy = Set.empty }) model.posts
    }

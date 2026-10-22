module Feature.Editor.State exposing (..)

import Api
import Domain
import Remote exposing (Remote(..))


type EditorMode
    = CreateTopic String
    | CreateReply String
    | EditPost String


type alias EditorAttachment =
    { id : String, name : String, reference : String }


type alias EditorState =
    { mode : EditorMode
    , title : String
    , body : String
    , format : String
    , version : Maybe String
    , attachments : List EditorAttachment
    , uploading : Bool
    , saving : Bool
    , problem : Maybe Api.Problem
    , conflict : Maybe Domain.Source
    }


emptyEditor : EditorMode -> EditorState
emptyEditor mode =
    { mode = mode
    , title = ""
    , body = ""
    , format = "markdown"
    , version = Nothing
    , attachments = []
    , uploading = False
    , saving = False
    , problem = Nothing
    , conflict = Nothing
    }


sourceAttachments : Domain.Source -> List EditorAttachment
sourceAttachments source =
    List.map (\id -> { id = id, name = id, reference = "/api/v1/media/" ++ id }) source.attachments


type alias Model =
    { editor : Maybe EditorState, source : Remote Domain.Source }


initial : Model
initial =
    { editor = Nothing, source = NotAsked }

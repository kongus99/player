module Playlist exposing (Msg(..), Playlist, adder, current, empty, lister, update)

import Dict exposing (Dict)
import Html as H
import Html.Attributes as A
import Html.Events as E
import List


type alias Entry =
    List String


type alias Playlist =
    { new : String, selected : String, backlog : Dict String Entry }


empty =
    Playlist "" "" Dict.empty


current : Playlist -> List String
current { selected, backlog } =
    Dict.get selected backlog |> Maybe.withDefault []


type Msg
    = SelectPlaylist String
    | AddPlaylist
    | DeletePlaylist
    | EditPlaylist String
    | ToggleSong String
    | RemoveSong String


update : Msg -> Playlist -> Playlist
update msg playlist =
    case msg of
        SelectPlaylist p ->
            { playlist | selected = p }

        AddPlaylist ->
            if String.isEmpty playlist.new then
                playlist
            else
                { playlist
                    | new = ""
                    , backlog = Dict.insert playlist.new [] playlist.backlog
                    , selected =
                        if playlist.selected == "" then
                            playlist.new
                        else
                            playlist.selected
                }

        EditPlaylist p ->
            { playlist | new = p }

        DeletePlaylist ->
            { playlist
                | selected = Dict.keys playlist.backlog |> List.head |> Maybe.withDefault ""
                , backlog = Dict.remove playlist.selected playlist.backlog
            }

        ToggleSong p ->
            let
                currentEntry =
                    current playlist
            in
            { playlist
                | backlog =
                    (if currentEntry |> List.member p then
                        List.filter (\e -> not (e == p)) currentEntry
                     else
                        List.append currentEntry [ p ]
                    )
                        |> flip (Dict.insert playlist.selected) playlist.backlog
            }

        RemoveSong p ->
            { playlist
                | backlog =
                    playlist.backlog
                        |> Dict.map (\k -> \entry -> entry |> List.filter (\e -> not (e == p)))
            }


adder playlist =
    H.div []
        [ H.input
            [ A.placeholder "Name"
            , E.onInput EditPlaylist
            , A.value playlist.new
            ]
            [ H.text playlist.new ]
        , H.button [ E.onClick <| AddPlaylist ] [ H.text "Add" ]
        ]


lister playlist =
    H.div []
        [ H.select [ E.onInput SelectPlaylist ]
            (Dict.keys playlist.backlog
                |> List.sort
                |> List.map
                    (\n ->
                        H.option
                            [ A.value n
                            , A.selected (n == playlist.selected)
                            ]
                            [ H.text n ]
                    )
            )
        , H.button [ E.onClick <| DeletePlaylist ] [ H.text "Remove" ]
        ]

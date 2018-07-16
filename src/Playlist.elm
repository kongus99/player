module Playlist exposing (Msg(..), Playlist, adder, current, empty, lister, update)

import Dict exposing (Dict)
import Html as H
import Html.Attributes as A
import Html.Events as E
import List


type alias Entry =
    List String


type alias Playlist =
    { new : String, selected : Maybe String, backlog : Dict String Entry }


empty =
    Playlist "" Nothing Dict.empty


current : Playlist -> Maybe (List String)
current { selected, backlog } =
    selected
        |> Maybe.andThen (flip Dict.get backlog)


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
            { playlist | selected = Just p }

        AddPlaylist ->
            if String.isEmpty playlist.new then
                playlist
            else
                { playlist
                    | new = ""
                    , backlog = Dict.insert playlist.new [] playlist.backlog
                    , selected =
                        if playlist.selected == Nothing then
                            Just playlist.new
                        else
                            playlist.selected
                }

        EditPlaylist p ->
            { playlist | new = p }

        DeletePlaylist ->
            { playlist
                | selected = Dict.keys playlist.backlog |> List.head
                , backlog =
                    playlist.selected
                        |> Maybe.map (flip Dict.remove playlist.backlog)
                        |> Maybe.withDefault Dict.empty
            }

        ToggleSong p ->
            let
                currentEntry =
                    current playlist
            in
            { playlist
                | backlog =
                    case ( currentEntry, playlist.selected ) of
                        ( Nothing, _ ) ->
                            playlist.backlog

                        ( _, Nothing ) ->
                            playlist.backlog

                        ( Just list, Just selected ) ->
                            (if list |> List.member p then
                                List.filter (\e -> not (e == p)) list
                             else
                                List.append list [ p ]
                            )
                                |> flip (Dict.insert selected) playlist.backlog
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
                            , A.selected (Just n == playlist.selected)
                            ]
                            [ H.text n ]
                    )
            )
        , H.button [ E.onClick <| DeletePlaylist ] [ H.text "Remove" ]
        ]

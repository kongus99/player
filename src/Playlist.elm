module Playlist exposing (Msg(..), Playlist, creator, current, empty, isEmpty, selector, update)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Form.Select as Select
import Dict exposing (Dict)
import FontAwesome as FA
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


isEmpty : Playlist -> Bool
isEmpty { backlog } =
    backlog |> Dict.isEmpty


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
            let
                newBacklog =
                    playlist.selected
                        |> Maybe.map (flip Dict.remove playlist.backlog)
                        |> Maybe.withDefault Dict.empty
            in
            { playlist
                | selected = Dict.keys newBacklog |> List.head
                , backlog = newBacklog
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


creator playlist =
    Form.form []
        [ Form.group []
            [ InputGroup.config
                (InputGroup.text [ Input.placeholder "Name", Input.onInput EditPlaylist, Input.value playlist.new ])
                |> InputGroup.successors
                    [ InputGroup.button [ Button.secondary, Button.onClick AddPlaylist ] [ FA.icon FA.save ] ]
                |> InputGroup.view
            ]
        , Form.group []
            [ H.div [ A.class "input-group" ]
                [ selector playlist
                , H.div [ A.class "input-group-append" ]
                    [ Button.button
                        [ Button.onClick <| DeletePlaylist
                        , Button.secondary
                        ]
                        [ FA.icon FA.trash ]
                    ]
                ]
            ]
        ]


selector playlist =
    H.select [ E.onInput SelectPlaylist, A.class "custom-select" ]
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

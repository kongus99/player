module Main exposing (..)

import Array exposing (Array)
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.CDN as CDN
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Grid as Grid
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Progress as Progress
import Dict exposing (Dict)
import FontAwesome as FA
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Item exposing (Item)
import Json.Decode as Dec
import Json.Encode as Enc
import LocalStorage exposing (LocalStorage)
import LocalStorage.SharedTypes as LSST
import MyModal
import Player
import Playlist exposing (Playlist)
import Set exposing (Set)
import Storage as St


---MODEL


type alias Model =
    { pool : Dict String Item
    , playlist : Playlist
    , playing : Maybe String
    , edited : Item
    , player : Player.Model
    , myModal : MyModal.Model
    , storage : LocalStorage Msg
    }


encodePool : Dict String Item -> Enc.Value
encodePool =
    let
        item ( k, i ) =
            Enc.object [ ( "name", Enc.string i.name ), ( "url", Enc.string i.url ) ]
    in
    Dict.toList >> List.map item >> Enc.list


decodePool : Dec.Value -> Dict String Item
decodePool value =
    let
        item =
            Dec.map2 Item.decode
                (Dec.field "name" Dec.string)
                (Dec.field "url" Dec.string)

        playlist =
            Dec.list item |> Dec.map (List.map (\e -> e.id |> Maybe.map (\id -> ( id, e ))) >> List.filterMap identity >> Dict.fromList)
    in
    case Dec.decodeValue playlist value of
        Ok res ->
            res

        Err err ->
            Dict.empty


main =
    H.program
        { init = init
        , subscriptions = St.subscriptions UpdatePorts
        , view = view
        , update = update
        }


init =
    let
        mdl =
            Model Dict.empty
                Playlist.empty
                Nothing
                Item.init
                Player.init
                MyModal.init
                St.init
    in
    mdl ! [ St.get "playlist" mdl ]


type Msg
    = Add Item
    | Remove
    | Play
    | Select String
    | EditMsg Item.Msg
    | PlaylistMsg Playlist.Msg
    | UpdatePorts LSST.Operation (Maybe (LSST.Ports Msg)) LSST.Key LSST.Value
    | ModalMsg (MyModal.Msg Msg)


getItem model getter =
    model.playlist
        |> Playlist.current
        |> Maybe.andThen List.head
        |> Maybe.andThen
            (flip Dict.get model.pool)
        |> Maybe.andThen getter


update msg model =
    case msg of
        Add item ->
            let
                mdl =
                    { model | pool = item.id |> Maybe.map (\id -> Dict.insert id item model.pool) |> Maybe.withDefault model.pool }
            in
            mdl ! [ St.set "playlist" (encodePool mdl.pool) mdl ]

        Remove ->
            let
                id =
                    getItem model .id

                mdl =
                    { model
                        | pool =
                            id
                                |> Maybe.map (flip Dict.remove model.pool)
                                |> Maybe.withDefault model.pool
                        , playlist =
                            id
                                |> Maybe.map (Playlist.RemoveSong >> flip Playlist.update model.playlist)
                                |> Maybe.withDefault model.playlist
                    }
            in
            mdl ! [ St.set "playlist" (encodePool mdl.pool) mdl ]

        Select id ->
            { model | playlist = Playlist.update (Playlist.ToggleSong id) model.playlist } ! []

        UpdatePorts operation ports key value ->
            let
                mdl =
                    case operation of
                        LSST.GetItemOperation ->
                            { model | pool = decodePool value }

                        _ ->
                            model
            in
            { mdl
                | storage =
                    case ports of
                        Nothing ->
                            model.storage

                        Just ps ->
                            LocalStorage.setPorts ps model.storage
            }
                ! []

        EditMsg iMsg ->
            let
                newItem =
                    Item.update iMsg model.edited
            in
            case iMsg of
                Item.Save i ->
                    { model | edited = newItem } |> update (Add i)

                _ ->
                    { model | edited = newItem } ! []

        PlaylistMsg iMsg ->
            --        TODO : reset playing when switching playlist
            { model | playlist = Playlist.update iMsg model.playlist } ! []

        Play ->
            let
                current =
                    getItem model .id
            in
            case ( current, model.playing ) of
                ( Just selected, Just playing ) ->
                    if selected == playing then
                        { model | playing = Nothing } ! [ Player.elmToPlayer Nothing ]
                    else
                        { model | playing = Just selected } ! [ current |> Player.elmToPlayer ]

                ( Just selected, Nothing ) ->
                    { model | playing = Just selected } ! [ current |> Player.elmToPlayer ]

                ( Nothing, _ ) ->
                    model ! []

        ModalMsg mMsg ->
            case mMsg of
                MyModal.UpdateModal m ->
                    update m model

                _ ->
                    { model | myModal = MyModal.update mMsg model.myModal } ! []


listItem current item =
    case item.id of
        Nothing ->
            []

        Just id ->
            [ ListGroup.button
                (List.append
                    (if Set.member id current then
                        [ ListGroup.secondary, ListGroup.active ]
                     else
                        []
                    )
                    [ ListGroup.attrs [ E.onClick (Select id) ] ]
                )
                [ H.text item.name ]
            ]


player item =
    [ Progress.progress
        [ Progress.label item.name
        , Progress.value 100
        , Progress.wrapperAttrs
            [ A.style [ ( "fontSize", "26px" ), ( "height", "50px" ) ]
            ]
        ]
    , ButtonGroup.linkButtonGroup
        [ ButtonGroup.small ]
        [ ButtonGroup.linkButton [ Button.primary, Button.onClick Play ] [ H.text "Play" ]
        , ButtonGroup.linkButton [ Button.secondary, Button.onClick Remove ] [ H.text "Remove" ]
        , ButtonGroup.linkButton [ Button.secondary, Button.attrs [ A.href item.url, A.target "_blank" ] ] [ H.text "Link" ]
        ]
    ]


buttons model =
    getItem model Just
        |> Maybe.map player
        |> Maybe.withDefault []


modalContents { myModal, playlist, edited } =
    case myModal.type_ of
        MyModal.PlaylistEditor ->
            Playlist.creator playlist |> H.map PlaylistMsg

        MyModal.ItemEditor ->
            Item.view edited |> H.map EditMsg


view model =
    let
        visibleWhenPlaylistExists element =
            if Playlist.isEmpty model.playlist then
                H.div [] []
            else
                element

        playlistControls =
            H.div [ A.class "input-group" ]
                [ H.div [ A.class "input-group-prepend" ]
                    [ H.map ModalMsg <| MyModal.trigger FA.list MyModal.PlaylistEditor ]
                , Playlist.selector model.playlist |> H.map PlaylistMsg |> visibleWhenPlaylistExists
                , H.div [ A.class "input-group-append" ]
                    [ H.map ModalMsg <| MyModal.trigger FA.plus MyModal.ItemEditor ]
                    |> visibleWhenPlaylistExists
                , H.map ModalMsg <| MyModal.contents (modalContents model) model.myModal
                ]
    in
    Grid.container [] <|
        CDN.stylesheet
            :: FA.useSvg
            :: playlistControls
            :: (case Playlist.current model.playlist |> Maybe.map Set.fromList of
                    Nothing ->
                        []

                    Just current ->
                        List.concat
                            [ buttons model
                            , [ ListGroup.custom
                                    (Dict.values model.pool
                                        |> List.sortBy .name
                                        |> List.map (listItem current)
                                        |> List.concatMap identity
                                    )
                              ]
                            ]
               )

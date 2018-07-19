module Main exposing (..)

import Array exposing (Array)
import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Dict exposing (Dict)
import FontAwesome as FA
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Item exposing (ValidItem)
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


type ModalType
    = Playlist


type alias Model =
    { pool : Dict String ValidItem
    , playlist : Playlist
    , playing : Maybe String
    , edited : Item.Model
    , player : Player.Model
    , myModalType : ModalType
    , myModal : MyModal.Model
    , storage : LocalStorage Msg
    }


encodePool : Dict String ValidItem -> Enc.Value
encodePool =
    let
        item ( k, i ) =
            Enc.object [ ( "name", Enc.string i.name ), ( "url", Enc.string i.url ) ]
    in
    Dict.toList >> List.map item >> Enc.list


decodePool : Dec.Value -> Dict String ValidItem
decodePool value =
    let
        item =
            Dec.map2 Item.decode
                (Dec.field "name" Dec.string)
                (Dec.field "url" Dec.string)

        playlist =
            Dec.list item |> Dec.map (List.filterMap identity >> List.map (\e -> ( e.id, e )) >> Dict.fromList)
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
                Playlist
                MyModal.init
                St.init
    in
    mdl ! [ St.get "playlist" mdl ]


type Msg
    = Add ValidItem
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
        |> Maybe.map getter


update msg model =
    case msg of
        Add item ->
            let
                mdl =
                    { model | pool = Dict.insert item.id item model.pool }
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


listItem : Set String -> ValidItem -> List (Html Msg)
listItem current item =
    [ H.div []
        [ H.input
            [ A.type_ "checkbox"
            , A.id item.url
            , A.name "playlist_item"
            , A.value item.name
            , A.checked (Set.member item.id current)
            , E.onClick (Select item.id)
            ]
            []
        , H.label [ A.for item.url ] [ H.text item.name ]
        ]
    ]


buttons model =
    let
        maybeItem =
            getItem model identity
    in
    maybeItem
        |> Maybe.map
            (\item ->
                [ H.button [ E.onClick Remove ]
                    [ H.text "Remove" ]
                , H.button [ E.onClick Play ]
                    [ H.text "Play" ]
                , H.a [ A.href item.url, A.target "_blank" ]
                    [ H.text item.name ]
                ]
            )
        |> Maybe.withDefault []


view model =
    let
        playlistControls =
            H.div [ A.class "input-group" ]
                [ H.div [ A.class "input-group-prepend" ]
                    [ H.map ModalMsg <| MyModal.trigger FA.list "Add/Remove Playlist" ]
                , if Playlist.isEmpty model.playlist then
                    H.div [] []
                  else
                    Playlist.selector model.playlist |> H.map PlaylistMsg
                ]
    in
    Grid.container [] <|
        CDN.stylesheet
            :: FA.useCss
            :: playlistControls
            :: (H.map ModalMsg <| MyModal.contents (Playlist.creator model.playlist |> H.map PlaylistMsg) model.myModal)
            :: (case Playlist.current model.playlist |> Maybe.map Set.fromList of
                    Nothing ->
                        []

                    Just current ->
                        List.concat
                            [ buttons model
                            , [ H.map EditMsg (Item.view model.edited)
                              , H.div []
                                    (Dict.values model.pool
                                        |> List.sortBy .name
                                        |> List.map (listItem current)
                                        |> List.concatMap identity
                                    )
                              ]
                            ]
               )

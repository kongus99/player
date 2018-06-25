module Playlist exposing (..)

import Array exposing (Array)
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Item exposing (Item)
import Json.Decode as Dec
import Json.Encode as Enc
import LocalStorage exposing (LocalStorage)
import LocalStorage.SharedTypes as LSST
import Player
import Storage as St


---MODEL


type alias Model =
    { playlist : Array Item, currentlyPlaying : Maybe Int, edited : Item, storage : LocalStorage Msg }


encodePlaylist : Array Item -> Enc.Value
encodePlaylist playlist =
    let
        item i =
            Enc.object [ ( "name", Enc.string i.name ), ( "url", Enc.string i.url ) ]
    in
    playlist |> Array.map item |> Enc.array


decodePlaylist : Dec.Value -> Array Item
decodePlaylist value =
    let
        item =
            Dec.map2 Item.decode
                (Dec.field "name" Dec.string)
                (Dec.field "url" Dec.string)

        playlist =
            Dec.array item
    in
    case Dec.decodeValue playlist value of
        Ok res ->
            res

        Err err ->
            Array.empty


main : Program Never Model Msg
main =
    H.program
        { init = init
        , subscriptions = St.subscriptions UpdatePorts
        , view = view
        , update = update
        }


init : ( Model, Cmd Msg )
init =
    let
        mdl =
            Model Array.empty Nothing Item.init St.init
    in
    mdl ! [ St.get "playlist" mdl ]


type Msg
    = Add Item
    | Remove Int
    | Play Int
    | EditMsg Item.Msg
    | UpdatePorts LSST.Operation (Maybe (LSST.Ports Msg)) LSST.Key LSST.Value


remove : List b -> Int -> List b
remove list index =
    list
        |> List.indexedMap
            (\ind ->
                \item ->
                    if ind == index then
                        Nothing
                    else
                        Just item
            )
        |> List.filterMap identity


get : Int -> List a -> Maybe a
get index list =
    list
        |> List.indexedMap
            (\ind ->
                \item ->
                    if ind == index then
                        Just item
                    else
                        Nothing
            )
        |> List.filterMap identity
        |> List.head


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Add item ->
            let
                mdl =
                    { model | playlist = Array.push item model.playlist }
            in
            mdl ! [ St.set "playlist" (encodePlaylist mdl.playlist) mdl ]

        Remove index ->
            let
                mdl =
                    { model
                        | playlist =
                            model.playlist
                                |> Array.toList
                                |> List.indexedMap
                                    (\i ->
                                        \e ->
                                            if i == index then
                                                Nothing
                                            else
                                                Just e
                                    )
                                |> List.filterMap identity
                                |> Array.fromList
                    }
            in
            mdl ! [ St.set "playlist" (encodePlaylist mdl.playlist) mdl ]

        Play index ->
            let
                newModel =
                    case model.currentlyPlaying of
                        Just int ->
                            { model
                                | currentlyPlaying =
                                    if int == index then
                                        Nothing
                                    else
                                        Just index
                            }

                        Nothing ->
                            { model | currentlyPlaying = Just index }

                cmds =
                    newModel.currentlyPlaying
                        |> Maybe.andThen (\i -> Array.get i newModel.playlist)
                        |> Maybe.andThen .id
                        |> Maybe.map (\id -> Player.elmToPlayer <| Just id)
                        |> Maybe.withDefault (Player.elmToPlayer Nothing)
            in
            newModel
                ! [ cmds ]

        EditMsg iMsg ->
            let
                newItem =
                    Item.update iMsg model.edited
            in
            case iMsg of
                Item.Save ->
                    { model | edited = newItem } |> update (Add model.edited)

                _ ->
                    { model | edited = newItem } ! []

        UpdatePorts operation ports key value ->
            let
                mdl =
                    case operation of
                        LSST.GetItemOperation ->
                            { model | playlist = decodePlaylist value, currentlyPlaying = Nothing }

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


listItem : Int -> Item -> Html Msg
listItem index item =
    H.li []
        [ H.text item.name
        , H.button [ A.title item.url, E.onClick (Play index) ] [ H.text "Play" ]
        , H.button [ A.title item.url, E.onClick (Remove index) ] [ H.text "Remove" ]
        ]


view : Model -> Html Msg
view model =
    H.div []
        [ H.map EditMsg (Item.view model.edited)
        , H.ul [] (List.indexedMap listItem (Array.toList model.playlist))
        ]

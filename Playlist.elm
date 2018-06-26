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
    { playlist : Array Item
    , selected : Maybe Int
    , playing : Maybe Int
    , edited : Item
    , storage : LocalStorage Msg
    }


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
            Model Array.empty Nothing Nothing Item.init St.init
    in
    mdl ! [ St.get "playlist" mdl ]


type Msg
    = Add Item
    | Remove
    | Play
    | Select Int
    | EditMsg Item.Msg
    | UpdatePorts LSST.Operation (Maybe (LSST.Ports Msg)) LSST.Key LSST.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Add item ->
            let
                mdl =
                    { model | playlist = Array.push item model.playlist }
            in
            mdl ! [ St.set "playlist" (encodePlaylist mdl.playlist) mdl ]

        Remove ->
            let
                mdl =
                    { model
                        | playlist =
                            model.selected
                                |> Maybe.map
                                    (\index ->
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
                                    )
                                |> Maybe.withDefault model.playlist
                    }
            in
            mdl ! [ St.set "playlist" (encodePlaylist mdl.playlist) mdl ]

        Select index ->
            { model
                | selected =
                    if model.selected == Just index then
                        Nothing
                    else
                        Just index
            }
                ! []

        Play ->
            let
                select selected model =
                    Array.get selected model.playlist
                        |> Maybe.andThen .id
            in
            case ( model.selected, model.playing ) of
                ( Just selected, Just playing ) ->
                    if selected == playing then
                        { model | playing = Nothing } ! [ Player.elmToPlayer Nothing ]
                    else
                        { model | playing = Just selected } ! [ select selected model |> Player.elmToPlayer ]

                ( Just selected, Nothing ) ->
                    { model | playing = Just selected } ! [ select selected model |> Player.elmToPlayer ]

                ( Nothing, _ ) ->
                    model ! []

        -- no changes, add independent play in future
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
                            { model | playlist = decodePlaylist value, selected = Nothing }

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


listItem : Int -> Int -> Item -> List (Html Msg)
listItem selected index item =
    [ H.div []
        [ H.input [ A.type_ "radio", A.id item.url, A.name "entry", A.value item.name, A.checked (selected == index), E.onClick (Select index) ] []
        , H.label [ A.for item.url ] [ H.text item.name ]
        ]
    ]


buttons : Model -> List (Html Msg)
buttons model =
    model.selected
        |> Maybe.map
            (\_ ->
                [ H.button [ E.onClick Remove ]
                    [ H.text "Remove" ]
                , H.button [ E.onClick Play ]
                    [ H.text "Play" ]
                ]
            )
        |> Maybe.withDefault []


view : Model -> Html Msg
view model =
    H.div [] <|
        List.append (buttons model)
            [ H.map EditMsg (Item.view model.edited)
            , H.div [] (List.indexedMap (listItem <| Maybe.withDefault -1 model.selected) (Array.toList model.playlist) |> List.concatMap identity)
            ]

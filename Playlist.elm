module Playlist exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Item exposing (ValidItem)
import Json.Decode as Dec
import Json.Encode as Enc
import LocalStorage exposing (LocalStorage)
import LocalStorage.SharedTypes as LSST
import Player
import Storage as St


---MODEL


type Mode
    = Single
    | Playlist


modeDecoder : String -> Mode
modeDecoder s =
    case s of
        "single" ->
            Single

        _ ->
            Playlist


modeEncoder : Mode -> String
modeEncoder s =
    case s of
        Single ->
            "single"

        Playlist ->
            "playlist"


type alias Model =
    { playlist : Dict String ValidItem
    , selected : Maybe String
    , playing : Maybe String
    , mode : Mode
    , edited : Item.Model
    , singlePlayer : Player.Model
    , playlistPlayer : Player.Model
    , storage : LocalStorage Msg
    }


encodePlaylist : Dict String ValidItem -> Enc.Value
encodePlaylist =
    let
        item ( k, i ) =
            Enc.object [ ( "name", Enc.string i.name ), ( "url", Enc.string i.url ) ]
    in
    Dict.toList >> List.map item >> Enc.list


decodePlaylist : Dec.Value -> Dict String ValidItem
decodePlaylist value =
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
            Model Dict.empty
                Nothing
                Nothing
                Single
                Item.init
                Player.init
                Player.init
                St.init
    in
    mdl ! [ St.get "playlist" mdl ]


type Msg
    = Add ValidItem
    | Remove
    | Play
    | Select String
    | EditMsg Item.Msg
    | UpdatePorts LSST.Operation (Maybe (LSST.Ports Msg)) LSST.Key LSST.Value
    | ModeChanged Mode


getItem : Model -> (ValidItem -> b) -> Maybe b
getItem model getter =
    model.selected
        |> Maybe.andThen
            (flip Dict.get model.playlist)
        |> Maybe.map getter


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Add item ->
            let
                mdl =
                    { model | playlist = Dict.insert item.id item model.playlist }
            in
            mdl ! [ St.set "playlist" (encodePlaylist mdl.playlist) mdl ]

        Remove ->
            let
                mdl =
                    { model
                        | playlist =
                            model.selected
                                |> Maybe.map (flip Dict.remove model.playlist)
                                |> Maybe.withDefault model.playlist
                    }
            in
            mdl ! [ St.set "playlist" (encodePlaylist mdl.playlist) mdl ]

        Select id ->
            { model
                | selected =
                    if model.selected == Just id then
                        Nothing
                    else
                        Just id
            }
                ! []

        Play ->
            let
                select model =
                    getItem model .id
            in
            case ( model.selected, model.playing ) of
                ( Just selected, Just playing ) ->
                    if selected == playing then
                        { model | playing = Nothing } ! [ Player.elmToPlayer Nothing ]
                    else
                        { model | playing = Just selected } ! [ select model |> Player.elmToPlayer ]

                ( Just selected, Nothing ) ->
                    { model | playing = Just selected } ! [ select model |> Player.elmToPlayer ]

                ( Nothing, _ ) ->
                    model ! []

        -- no changes, add independent play in future
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

        ModeChanged m ->
            { model | mode = m } ! []


listItem : Maybe String -> ValidItem -> List (Html Msg)
listItem selected item =
    [ H.div []
        [ H.input
            [ A.type_ "radio"
            , A.id item.url
            , A.name "entry"
            , A.value item.name
            , A.checked (selected == Just item.id)
            , E.onClick (Select item.id)
            ]
            []
        , H.label [ A.for item.url ] [ H.text item.name ]
        ]
    ]


buttons : Model -> List (Html Msg)
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


view : Model -> Html Msg
view model =
    H.div [] <|
        List.concat
            [ [ H.select [ E.onInput (modeDecoder >> ModeChanged) ]
                    [ H.option [ Single |> modeEncoder |> A.value ] [ Single |> modeEncoder |> H.text ]
                    , H.option [ Playlist |> modeEncoder |> A.value ] [ Playlist |> modeEncoder |> H.text ]
                    ]
              ]
            , buttons model
            , [ H.map EditMsg (Item.view model.edited)
              , H.div []
                    (Dict.values model.playlist
                        |> List.sortBy .name
                        |> List.map (listItem model.selected)
                        |> List.concatMap identity
                    )
              ]
            ]

port module Player exposing (Model, Msg(..), decode, elmToPlayer, init)

import Array exposing (Array)
import Item exposing (Item)


-- -1 – unstarted
-- 0 – ended
-- 1 – playing
-- 2 – paused
-- 3 – buffering
-- 5 – video cued


type State
    = Ended
    | Paused
    | Playing
    | Other


type Msg
    = Play (Array Item)
    | Toggle
    | StateChange State


type alias Model =
    { state : State, items : Array Item, index : Int }


init : Model
init =
    Model Ended Array.empty 0



-- type alias EncodedMsg =
--     { type_ : String, payload : Maybe String }


decode : Int -> State
decode state =
    case state of
        0 ->
            Ended

        1 ->
            Playing

        2 ->
            Paused

        _ ->
            Other


playCmd : Model -> List (Cmd msg)
playCmd { index, items } =
    [ items
        |> Array.get index
        |> Maybe.andThen .id
        |> elmToPlayer
    ]


update : Model -> Msg -> ( Model, Cmd msg )
update model msg =
    case msg of
        Play items ->
            let
                newModel =
                    { model | items = items, index = 0 }
            in
            newModel ! playCmd newModel

        Toggle ->
            case model.state of
                Playing ->
                    { model | state = Paused } ! [ elmToPlayer <| Nothing ]

                Paused ->
                    { model | state = Playing } ! playCmd model

                _ ->
                    model ! []

        StateChange state ->
            case state of
                Ended ->
                    let
                        newModel =
                            { model
                                | state = state
                                , index = (model.index + 1) % Array.length model.items
                            }
                    in
                    newModel ! playCmd newModel

                _ ->
                    { model | state = state } ! []


port elmToPlayer : Maybe String -> Cmd msg


port playerToElm : (Int -> msg) -> Sub msg

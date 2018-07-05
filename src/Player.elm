port module Player exposing (Model, Msg(..), elmToPlayer, init)

import Array exposing (Array)
import Item exposing (ValidItem)


type Msg
    = Play (Array ValidItem)
    | Toggle
    | StateChange Int



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


type alias Model =
    { state : State, items : Array ValidItem, index : Int }


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


playCmd : Int -> Array ValidItem -> List (Cmd msg)
playCmd index items =
    [ items
        |> Array.get index
        |> Maybe.map .id
        |> elmToPlayer
    ]


update : Model -> Msg -> ( Model, Cmd msg )
update model msg =
    case msg of
        Play items ->
            { model | items = items, index = 0 }
                ! playCmd 0 items

        Toggle ->
            case model.state of
                Playing ->
                    { model | state = Paused } ! [ elmToPlayer <| Nothing ]

                Paused ->
                    { model | state = Playing } ! playCmd model.index model.items

                _ ->
                    model ! []

        StateChange state ->
            let
                newModel =
                    { model | state = decode state }
            in
            case newModel.state of
                Ended ->
                    let
                        index =
                            (newModel.index + 1) % Array.length newModel.items
                    in
                    { model | index = index } ! playCmd index model.items

                _ ->
                    newModel ! []


port elmToPlayer : Maybe String -> Cmd msg


port playerToElm : (Int -> msg) -> Sub msg

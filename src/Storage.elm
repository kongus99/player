port module Storage exposing (get, init, set, subscriptions)

import LocalStorage exposing (LocalStorage)
import LocalStorage.SharedTypes as LSST


init : LocalStorage msg
init =
    LocalStorage.make ports prefix


get : String -> { a | storage : LocalStorage msg } -> Cmd msg
get key { storage } =
    LocalStorage.getItem storage key


set : String -> LSST.Value -> { a | storage : LocalStorage msg } -> Cmd msg
set key value { storage } =
    LocalStorage.setItem storage key value


prefix : String
prefix =
    "playlists"


ports : LSST.Ports msg
ports =
    LocalStorage.makeRealPorts getItem setItem clear listKeys


port getItem : LSST.GetItemPort msg


port setItem : LSST.SetItemPort msg


port clear : LSST.ClearPort msg


port listKeys : LSST.ListKeysPort msg


port receiveItem : LSST.ReceiveItemPort msg


subscriptions :
    LSST.MsgWrapper msg
    -> { a | storage : LocalStorage msg }
    -> Sub msg
subscriptions msg { storage } =
    let
        prefix =
            LocalStorage.getPrefix storage
    in
    receiveItem <| LSST.receiveWrapper msg prefix

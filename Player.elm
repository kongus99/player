port module Player exposing (..)

-- port for sending strings out to JavaScript


port elmToPlayer : Maybe String -> Cmd msg



-- port for listening for suggestions from JavaScript


port playerToElm : (List String -> msg) -> Sub msg

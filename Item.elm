module Item exposing (..)

import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Pathfinder as PF exposing ((<=>), (<?>), ParsingResult(Str), any, p, parse, str)


type alias Item =
    { name : String, id : Maybe String, url : String }


init : Item
init =
    Item "" Nothing ""

decode : String -> String -> Item
decode name url =
    Item name (parseUrl url) url


type Msg
    = ChangeName String
    | ChangeUrl String
    | Save


parseUrl : String -> Maybe String
parseUrl url =
    case parse (any <?> (p "v" <=> str)) url of
        Str id ->
            Just id

        _ ->
            Nothing


update : Msg -> Item -> Item
update msg model =
    case msg of
        ChangeName n ->
            { model | name = n }

        ChangeUrl n ->
            { model | id = parseUrl n, url = n }

        Save ->
            init


view : Item -> Html Msg
view model =
    H.div []
        [ H.input
            [ A.placeholder "Name"
            , E.onInput ChangeName
            , A.value model.name
            ]
            [ H.text model.name ]
        , H.input
            [ A.placeholder "Url"
            , E.onInput ChangeUrl
            , A.value model.url
            ]
            [ H.text model.url ]
        , H.button [ E.onClick Save ] [ H.text "Save" ]
        ]

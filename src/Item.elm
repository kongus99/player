module Item exposing (Item, Msg(Save), decode, init, update, view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import FontAwesome as FA
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Pathfinder as PF exposing ((<=>), (<?>), ParsingResult(Str), any, p, parse, str)


type alias Item =
    { name : String, id : Maybe String, url : String }


init : Item
init =
    Item "" Nothing ""


parseUrl : String -> Maybe String
parseUrl url =
    case parse (any <?> (p "v" <=> str)) url of
        Str id ->
            Just id

        _ ->
            Nothing


decode : String -> String -> Item
decode name url =
    Item name (parseUrl url) url


type Msg
    = ChangeName String
    | ChangeUrl String
    | Save Item
    | Remove String
    | Clear


update : Msg -> Item -> Item
update msg item =
    let
        updateItem url name =
            case String.length name of
                0 ->
                    Item name Nothing ""

                _ ->
                    Item name (parseUrl url) url
    in
    case msg of
        ChangeName n ->
            updateItem item.url n

        ChangeUrl n ->
            updateItem n item.name

        Save i ->
            update Clear item

        Remove id ->
            item

        Clear ->
            init


view : Item -> Html Msg
view item =
    Form.form []
        [ Form.group []
            [ Input.text
                [ Input.placeholder "Name", Input.onInput ChangeName, Input.value item.name ]
            ]
        , Form.group []
            [ Input.text
                [ Input.placeholder "Url", Input.onInput ChangeUrl, Input.value item.url ]
            ]
        , Form.group []
            (case item.id of
                Just id ->
                    [ Button.button [ Button.onClick <| Save item, Button.secondary ] [ FA.icon FA.save ]
                    , Button.button [ Button.onClick <| Clear, Button.secondary ] [ FA.icon FA.eraser ]
                    , Button.button [ Button.onClick <| Remove id, Button.secondary ] [ FA.icon FA.trash ]
                    ]

                Nothing ->
                    [ H.div [] [ Button.button [ Button.onClick <| Clear, Button.secondary ] [ FA.icon FA.eraser ] ] ]
            )
        ]

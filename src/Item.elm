module Item exposing (Model, Msg(Save), ValidItem, decode, init, update, view)

import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Pathfinder as PF exposing ((<=>), (<?>), ParsingResult(Str), any, p, parse, str)


type alias Item =
    { name : String, url : String }


type alias ValidItem =
    { name : String, id : String, url : String }


type Model
    = Incorrect Item
    | Correct ValidItem


init : Model
init =
    Incorrect <| Item "" ""


parseUrl : String -> Maybe String
parseUrl url =
    case parse (any <?> (p "v" <=> str)) url of
        Str id ->
            Just id

        _ ->
            Nothing


decode : String -> String -> Maybe ValidItem
decode name url =
    parseUrl url |> Maybe.map (\id -> ValidItem name id url)


getUrl : Model -> String
getUrl model =
    case model of
        Incorrect i ->
            i.url

        Correct i ->
            i.url


getName : Model -> String
getName model =
    case model of
        Incorrect i ->
            i.name

        Correct i ->
            i.name


type Msg
    = ChangeName String
    | ChangeUrl String
    | Save ValidItem
    | Remove String
    | Clear


update : Msg -> Model -> Model
update msg model =
    let
        updateItem url name =
            case ( parseUrl url, String.length name ) of
                ( _, 0 ) ->
                    Incorrect (Item name url)

                ( Just id, _ ) ->
                    Correct (ValidItem name id url)

                ( Nothing, _ ) ->
                    Incorrect (Item name url)
    in
    case msg of
        ChangeName n ->
            updateItem (getUrl model) n

        ChangeUrl n ->
            updateItem n (getName model)

        Save i ->
            update Clear model

        Remove id ->
            model

        Clear ->
            init


view : Model -> Html Msg
view model =
    H.div []
        (List.append
            [ H.input
                [ A.placeholder "Name"
                , E.onInput ChangeName
                , A.value (getName model)
                ]
                [ H.text (getName model) ]
            , H.input
                [ A.placeholder "Url"
                , E.onInput ChangeUrl
                , A.value (getUrl model)
                ]
                [ H.text (getUrl model) ]
            ]
            (case model of
                Correct i ->
                    [ H.button [ E.onClick <| Save i ] [ H.text "Save" ]
                    , H.button [ E.onClick <| Clear ] [ H.text "Clear" ]
                    , H.button [ E.onClick <| Remove i.id ] [ H.text "Remove" ]
                    ]

                Incorrect i ->
                    [ H.button [ E.onClick <| Clear ] [ H.text "Clear" ] ]
            )
        )

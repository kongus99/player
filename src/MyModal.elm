module MyModal exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import FontAwesome as FA
import Html as H exposing (Html)
import Html.Events as E


type alias Model =
    { modalVisibility : Modal.Visibility, title : String }


init =
    { modalVisibility = Modal.hidden, title = "" }


type Msg msg
    = CloseModal
    | ShowModal String
    | UpdateModal msg


update msg model =
    case msg of
        CloseModal ->
            init

        ShowModal title ->
            { model | modalVisibility = Modal.shown, title = title }

        UpdateModal msg ->
            model


trigger icon title =
    Button.button
        [ Button.outlinePrimary
        , Button.attrs [ E.onClick <| ShowModal title ]
        ]
        [ FA.icon icon ]


contents content model =
    H.div []
        [ Modal.config CloseModal
            |> Modal.small
            |> Modal.hideOnBackdropClick True
            |> Modal.h3 [] [ H.text model.title ]
            |> Modal.body [] [ content |> H.map UpdateModal ]
            |> Modal.view model.modalVisibility
        ]

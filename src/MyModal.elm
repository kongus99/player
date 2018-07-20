module MyModal exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import FontAwesome as FA
import Html as H exposing (Html)
import Html.Events as E


type ModalType
    = PlaylistEditor
    | ItemEditor


type alias Model =
    { modalVisibility : Modal.Visibility, type_ : ModalType }


init =
    { modalVisibility = Modal.hidden, type_ = PlaylistEditor }


type Msg msg
    = CloseModal
    | ShowModal ModalType
    | UpdateModal msg


title type_ =
    case type_ of
        PlaylistEditor ->
            "Add/Remove Playlist"

        ItemEditor ->
            "Add song"


update msg model =
    case msg of
        CloseModal ->
            init

        ShowModal type_ ->
            { model | modalVisibility = Modal.shown, type_ = type_ }

        UpdateModal msg ->
            model


trigger icon type_ =
    Button.button
        [ Button.outlinePrimary
        , Button.attrs [ E.onClick <| ShowModal type_ ]
        ]
        [ FA.icon icon ]


contents content model =
    H.div []
        [ Modal.config CloseModal
            |> Modal.small
            |> Modal.hideOnBackdropClick True
            |> Modal.h3 [] [ H.text <| title model.type_ ]
            |> Modal.body [] [ content |> H.map UpdateModal ]
            |> Modal.view model.modalVisibility
        ]

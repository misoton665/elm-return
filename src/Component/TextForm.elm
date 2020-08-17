module Component.TextForm exposing (Model, Msg, Output(..), Query(..), empty, update, updateByQuery, view)

import Component.TextInput as TextInput
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Support.Return exposing (Return, clearOutputs, mapCmd, returnOutput, transformModel)


type Model
    = Model
        { textInput : TextInput.Model
        }


textInput : Model -> TextInput.Model
textInput (Model m) =
    m.textInput


empty : Model
empty =
    Model { textInput = TextInput.empty }


type Output
    = ButtonClicked String


type Query
    = TellClear


updateByQuery : Query -> Return Model Msg Output
updateByQuery query =
    case query of
        TellClear ->
            TextInput.updateByQuery TextInput.TellClear
                |> transformFromTextInput


transformFromTextInput : Return TextInput.Model TextInput.Msg TextInput.Output -> Return Model Msg Output
transformFromTextInput =
    transformModel textInput (\(Model m) t -> Model { m | textInput = t })
        >> mapCmd TextInputMsg
        >> clearOutputs


type Msg
    = TextInputMsg TextInput.Msg
    | ClickedButton


update : Msg -> Model -> Return Model Msg Output
update msg model =
    case msg of
        TextInputMsg msg_ ->
            TextInput.update msg_
                |> transformFromTextInput

        ClickedButton ->
            returnOutput <| ButtonClicked <| (textInput >> TextInput.text) model


view : Model -> Html Msg
view model =
    div []
        [ TextInput.view (textInput model) |> Html.map TextInputMsg
        , button [ onClick ClickedButton ] [ text "Enter" ]
        ]

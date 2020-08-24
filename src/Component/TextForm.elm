module Component.TextForm exposing (Model, Msg, Output(..), empty, update, clear, view)

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


clear : Return Model Msg out
clear =
    TextInput.clear
        |> transformFromTextInput
        |> clearOutputs


transformFromTextInput : Return TextInput.Model TextInput.Msg out -> Return Model Msg out
transformFromTextInput =
    transformModel textInput (\(Model m) t -> Model { m | textInput = t })
        >> mapCmd TextInputMsg


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
            (textInput >> TextInput.text) model
                |> ButtonClicked
                |> returnOutput


view : Model -> Html Msg
view model =
    div []
        [ TextInput.view (textInput model) |> Html.map TextInputMsg
        , button [ onClick ClickedButton ] [ text "Enter" ]
        ]

module Component.TextInput exposing (Model, Msg, Output(..), empty, new, text, update, setText, clear, view)

import Html exposing (Attribute, Html, input)
import Html.Attributes exposing (type_, value)
import Html.Events exposing (onInput)
import Support.Return exposing (Return, returnModel, withOutput)


type Model
    = TextInput String


text : Model -> String
text (TextInput t) =
    t


new : String -> Model
new =
    TextInput


empty : Model
empty =
    new ""


type Output
    = DoneClear


setText : String -> Return Model msg out
setText t =
    returnModel <| \_ -> new t


clear : Return Model msg Output
clear =
    returnModel (\_ -> empty)
        |> withOutput DoneClear


type Msg
    = Entered String


update : Msg -> Return Model msg out
update msg =
    case msg of
        Entered t ->
            setText t


view : Model -> Html Msg
view (TextInput t) =
    input [ type_ "text", onInput Entered, value t ] []

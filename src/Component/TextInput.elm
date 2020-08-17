module Component.TextInput exposing (Model, Msg, Output(..), Query(..), empty, new, text, update, updateByQuery, view)

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


type Query
    = TellText String
    | TellClear


updateByQuery : Query -> Return Model Msg Output
updateByQuery query =
    case query of
        TellText t ->
            returnModel <| \_ -> new t

        TellClear ->
            returnModel (\_ -> empty)
                |> withOutput DoneClear


type Msg
    = Entered String


update : Msg -> Return Model Msg Output
update msg =
    case msg of
        Entered t ->
            returnModel (\_ -> new t)


view : Model -> Html Msg
view (TextInput t) =
    input [ type_ "text", onInput Entered, value t ] []

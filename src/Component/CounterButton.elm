module Component.CounterButton exposing (Model, Msg, Output(..), Query(..), update, updateByQuery, view, zero)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Support.Return exposing (Return, returnModel, returnOutput, withOutput)


type Model
    = CounterButton Int


countUp : Model -> Model
countUp (CounterButton count) =
    CounterButton <| count + 1


zero : Model
zero =
    CounterButton 0


count_ : Model -> Int
count_ (CounterButton count) =
    count


type Output
    = Count Int
    | DoneResetting


type Query
    = RequestCount
    | TellResetting


updateByQuery : Model -> Query -> Return Model Msg Output
updateByQuery model query =
    case query of
        RequestCount ->
            returnOutput <| Count <| count_ model

        TellResetting ->
            returnModel (\_ -> zero)
                |> withOutput DoneResetting


type Msg
    = ClickedCountUp
    | ClickedReset


update : Msg -> Return Model Msg Output
update msg =
    case msg of
        ClickedCountUp ->
            returnModel countUp

        ClickedReset ->
            returnModel (\_ -> zero)
                |> withOutput DoneResetting


view : Html Msg
view =
    div []
        [ button [ onClick ClickedCountUp ] [ text "Count up" ]
        , button [ onClick ClickedReset ] [ text "Reset" ]
        ]

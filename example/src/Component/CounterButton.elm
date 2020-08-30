module Component.CounterButton exposing (Model, count, Msg, Output(..), update, reset, view, zero)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Return exposing (Return, returnModel, withOutput)


type Model
    = CounterButton Int


countUp : Model -> Model
countUp (CounterButton c) =
    CounterButton <| c + 1


zero : Model
zero =
    CounterButton 0


reset : Return Model Msg Output
reset =
    returnModel (\_ -> zero)
        |> withOutput DoneResetting


count : Model -> Int
count (CounterButton c) =
    c


type Output
    = DoneResetting


type Msg
    = ClickedCountUp
    | ClickedReset


update : Msg -> Return Model Msg Output
update msg =
    case msg of
        ClickedCountUp ->
            returnModel countUp

        ClickedReset ->
            reset


view : Html Msg
view =
    div []
        [ button [ onClick ClickedCountUp ] [ text "Count up" ]
        , button [ onClick ClickedReset ] [ text "Reset" ]
        ]

module MainSingleButton exposing (main)

import Browser
import Component.CounterButton as CounterButton
import Html exposing (Html, br, button, div, text)
import Html.Events exposing (onClick)
import Messages as Messages exposing (Messages)
import Support.Return as Return exposing (Return, returnModel)


main : Platform.Program Flag Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = updateForMain
        , subscriptions = subscriptions
        }


type alias Flag =
    ()


type alias Model =
    { counterButton : CounterButton.Model
    , messages : Messages
    }


pushCountMessage : Int -> Messages -> Messages
pushCountMessage count =
    Messages.push ("Count: " ++ String.fromInt count)


pushResetMessage : Messages -> Messages
pushResetMessage =
    Messages.push "Reset"


type Msg
    = CounterButtonMsg CounterButton.Msg
    | ClickedResetButton
    | ClickedLookButton


init : Flag -> ( Model, Cmd Msg )
init _ =
    ( { counterButton = CounterButton.zero
      , messages = Messages.empty
      }
    , Cmd.none
    )


updateForMain : Msg -> Model -> ( Model, Cmd Msg )
updateForMain msg model =
    update msg model
        |> (\r -> ( Return.applyModel r model, Return.asCmd r ))


update : Msg -> Model -> Return Model Msg Never
update msg model =
    case msg of
        CounterButtonMsg msg_ ->
            CounterButton.update msg_
                |> transformFromCounterButton
                |> Return.consumeOutputs updateByCounterButtonOutput

        ClickedResetButton ->
            CounterButton.reset
                |> transformFromCounterButton
                |> Return.consumeOutputs updateByCounterButtonOutput

        ClickedLookButton ->
            returnModel (pushCountMessage <| CounterButton.count model.counterButton)
                |> transformFromMessages


updateByCounterButtonOutput : CounterButton.Output -> Return Model Msg out
updateByCounterButtonOutput output =
    case output of
        CounterButton.DoneResetting ->
            returnModel pushResetMessage
                |> transformFromMessages


transformFromCounterButton : Return CounterButton.Model CounterButton.Msg out -> Return Model Msg out
transformFromCounterButton =
    Return.transformModel .counterButton (\model counterButton -> { model | counterButton = counterButton })
        >> Return.mapCmd CounterButtonMsg


transformFromMessages : Return Messages msg out -> Return Model msg out
transformFromMessages =
    Return.transformModel .messages (\model m -> { model | messages = m })


view : Model -> Html Msg
view model =
    div []
        [ CounterButton.view |> Html.map CounterButtonMsg
        , button [ onClick ClickedResetButton ] [ text "Reset" ]
        , button [ onClick ClickedLookButton ] [ text "Look count" ]
        , messagesView model.messages
        ]


messagesView : Messages -> Html Msg
messagesView =
    Messages.asList
        >> List.map text
        >> List.intersperse (br [] [])
        >> div []


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

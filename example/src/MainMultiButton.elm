module MainMultiButton exposing (main)

import Browser
import Component.CounterButton as CounterButton
import Component.TextForm as TextForm
import Html exposing (Html, br, button, div, text)
import Html.Events exposing (onClick)
import Messages as Messages exposing (Messages)
import Return exposing (Return, returnModel)


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
    { counterButton1 : CounterButton.Model
    , counterButton2 : CounterButton.Model
    , textForm : TextForm.Model
    , messages : Messages
    }


pushCountMessage : Int -> Messages -> Messages
pushCountMessage count =
    Messages.push <| "Count: " ++ String.fromInt count


pushResetMessage : Messages -> Messages
pushResetMessage =
    Messages.push "Reset"


type Msg
    = CounterButtonMsg1 CounterButton.Msg
    | CounterButtonMsg2 CounterButton.Msg
    | TextFormMsg TextForm.Msg
    | ClickedResetButton
    | ClickedLookButton


init : Flag -> ( Model, Cmd Msg )
init _ =
    ( { counterButton1 = CounterButton.zero
      , counterButton2 = CounterButton.zero
      , textForm = TextForm.empty
      , messages = Messages.empty
      }
    , Cmd.none
    )


updateForMain : Msg -> Model -> ( Model, Cmd Msg )
updateForMain msg model =
    update msg model
        |> (\r -> ( Return.applyModel r model, Return.asCmd r ))


update : Msg -> Model -> Return Model Msg out
update msg model =
    case msg of
        CounterButtonMsg1 msg_ ->
            CounterButton.update msg_
                |> transformFromCounterButton1
                |> Return.consumeOutputs updateByCounterButtonOutput

        CounterButtonMsg2 msg_ ->
            CounterButton.update msg_
                |> transformFromCounterButton2
                |> Return.consumeOutputs updateByCounterButtonOutput

        TextFormMsg msg_ ->
            TextForm.update msg_ model.textForm
                |> transformFromTextForm
                |> Return.consumeOutputs updateByTextFormOutput

        ClickedResetButton ->
            let
                resetCounter1 =
                    CounterButton.reset
                        |> transformFromCounterButton1
                        |> Return.consumeOutputs updateByCounterButtonOutput

                resetCounter2 =
                    CounterButton.reset
                        |> transformFromCounterButton2
                        |> Return.consumeOutputs updateByCounterButtonOutput

                pushMessage =
                    returnModel (Messages.push "ResetAll")
                        |> transformFromMessages
            in
            Return.mergeAll [ resetCounter1, resetCounter2, pushMessage ]

        ClickedLookButton ->
            let
                pushCount =
                    CounterButton.count >> pushCountMessage
            in
            returnModel (pushCount model.counterButton1 >> pushCount model.counterButton2)
                |> transformFromMessages


updateByCounterButtonOutput : CounterButton.Output -> Return Model msg out
updateByCounterButtonOutput output =
    case output of
        CounterButton.DoneResetting ->
            returnModel pushResetMessage
                |> transformFromMessages


updateByTextFormOutput : TextForm.Output -> Return Model Msg out
updateByTextFormOutput output =
    case output of
        TextForm.ButtonClicked txt ->
            let
                pushMessage =
                    returnModel (Messages.push txt)
                        |> transformFromMessages

                clearForm =
                    TextForm.clear
                        |> transformFromTextForm
            in
            Return.merge pushMessage clearForm


transformFromCounterButton1 : Return CounterButton.Model CounterButton.Msg out -> Return Model Msg out
transformFromCounterButton1 =
    Return.transformModel .counterButton1 (\model c -> { model | counterButton1 = c })
        >> Return.mapCmd CounterButtonMsg1


transformFromCounterButton2 : Return CounterButton.Model CounterButton.Msg out -> Return Model Msg out
transformFromCounterButton2 =
    Return.transformModel .counterButton2 (\model c -> { model | counterButton2 = c })
        >> Return.mapCmd CounterButtonMsg2


transformFromMessages : Return Messages msg out -> Return Model msg out
transformFromMessages =
    Return.transformModel .messages (\model m -> { model | messages = m })


transformFromTextForm : Return TextForm.Model TextForm.Msg out -> Return Model Msg out
transformFromTextForm =
    Return.transformModel .textForm (\model t -> { model | textForm = t })
        >> Return.mapCmd TextFormMsg


view : Model -> Html Msg
view model =
    div []
        [ CounterButton.view |> Html.map CounterButtonMsg1
        , CounterButton.view |> Html.map CounterButtonMsg2
        , button [ onClick ClickedResetButton ] [ text "Reset" ]
        , button [ onClick ClickedLookButton ] [ text "Look up counts" ]
        , TextForm.view model.textForm |> Html.map TextFormMsg
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

module MainMultiButton exposing (main)

import Browser
import Component.CounterButton as CounterButton
import Component.TextForm as TextForm
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
    ( { counterButton1 = CounterButton.zero, counterButton2 = CounterButton.zero, textForm = TextForm.empty, messages = Messages.empty }
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

        CounterButtonMsg2 msg_ ->
            CounterButton.update msg_
                |> transformFromCounterButton2

        TextFormMsg msg_ ->
            TextForm.update msg_ model.textForm
                |> transformFromTextForm

        ClickedResetButton ->
            let
                return1 =
                    CounterButton.updateByQuery model.counterButton1 CounterButton.TellResetting
                        |> transformFromCounterButton1

                return2 =
                    CounterButton.updateByQuery model.counterButton2 CounterButton.TellResetting
                        |> transformFromCounterButton2

                return3 =
                    returnModel (Messages.push "ResetAll")
                        |> transformFromMessages
            in
            Return.mergeAll [ return1, return2, return3 ]

        ClickedLookButton ->
            let
                return1 =
                    CounterButton.updateByQuery model.counterButton1 CounterButton.RequestCount
                        |> transformFromCounterButton1

                return2 =
                    CounterButton.updateByQuery model.counterButton2 CounterButton.RequestCount
                        |> transformFromCounterButton2
            in
            Return.merge return1 return2


updateByCounterButtonOutput : CounterButton.Output -> Return Model msg out
updateByCounterButtonOutput output =
    case output of
        CounterButton.Count count ->
            returnModel (pushCountMessage count)
                |> transformFromMessages

        CounterButton.DoneResetting ->
            returnModel pushResetMessage
                |> transformFromMessages


updateByTextFormOutput : TextForm.Output -> Return Model Msg out
updateByTextFormOutput output =
    case output of
        TextForm.ButtonClicked txt ->
            let
                push =
                    returnModel (Messages.push txt)
                        |> transformFromMessages

                clear =
                    TextForm.updateByQuery TextForm.TellClear
                        |> transformFromTextForm
            in
            Return.merge push clear


transformFromCounterButton1 : Return CounterButton.Model CounterButton.Msg CounterButton.Output -> Return Model Msg out
transformFromCounterButton1 =
    Return.transformModel .counterButton1 (\model c -> { model | counterButton1 = c })
        >> Return.mapCmd CounterButtonMsg1
        >> Return.handleOutputs updateByCounterButtonOutput
        >> Return.clearOutputs


transformFromCounterButton2 : Return CounterButton.Model CounterButton.Msg CounterButton.Output -> Return Model Msg out
transformFromCounterButton2 =
    Return.transformModel .counterButton2 (\model c -> { model | counterButton2 = c })
        >> Return.mapCmd CounterButtonMsg2
        >> Return.handleOutputs updateByCounterButtonOutput
        >> Return.clearOutputs


transformFromMessages : Return Messages msg out -> Return Model msg out
transformFromMessages =
    Return.transformModel .messages (\model m -> { model | messages = m })


transformFromTextForm : Return TextForm.Model TextForm.Msg TextForm.Output -> Return Model Msg out
transformFromTextForm =
    Return.transformModel .textForm (\model t -> { model | textForm = t })
        >> Return.mapCmd TextFormMsg
        >> Return.handleOutputs updateByTextFormOutput
        >> Return.clearOutputs


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

module Support.Return exposing
    ( Return
    , applyModel
    , asCmd
    , asOutputs
    , clearOutputs
    , handleOutputs
    , mapCmd
    , mapOutputs
    , merge
    , mergeAll
    , returnCmd
    , returnModel
    , returnNothing
    , returnOutput
    , returnOutputs
    , transformModel
    , withCmd
    , withModel
    , withOutput
    , withOutputs
    )


type Return model msg output
    = Return
        { modelModifierM : Maybe (ModelModifier model)
        , cmd : Cmd msg
        , outputs : List output
        }


type alias ModelModifier mod =
    mod -> mod



-- Get


asModelModifier : Return mod msg out -> Maybe (ModelModifier mod)
asModelModifier (Return { modelModifierM }) =
    modelModifierM


asCmd : Return mod msg out -> Cmd msg
asCmd (Return { cmd }) =
    cmd


asOutputs : Return mod msg out -> List out
asOutputs (Return { outputs }) =
    outputs



-- With: Decorate a generated Return.


type alias WithF mod msg out a =
    a -> Return mod msg out -> Return mod msg out


withModel : WithF mod msg out (ModelModifier mod)
withModel model (Return { modelModifierM, cmd, outputs }) =
    Return
        { modelModifierM = mergeMaybeModel modelModifierM (Just model)
        , cmd = cmd
        , outputs = outputs
        }


withCmd : WithF mod msg out (Cmd msg)
withCmd cmd_ (Return { modelModifierM, cmd, outputs }) =
    Return
        { modelModifierM = modelModifierM
        , cmd = mergeCmd cmd cmd_
        , outputs = outputs
        }


withOutput : WithF mod msg out out
withOutput output (Return { modelModifierM, cmd, outputs }) =
    Return
        { modelModifierM = modelModifierM
        , cmd = cmd
        , outputs = pushOutput output outputs
        }


withOutputs : WithF mod msg out (List out)
withOutputs outputs_ (Return { modelModifierM, cmd, outputs }) =
    Return
        { modelModifierM = modelModifierM
        , cmd = cmd
        , outputs = mergeOutputs outputs outputs_
        }



-- Generate Return


returnNothing : Return mod msg out
returnNothing =
    Return
        { modelModifierM = Nothing
        , cmd = Cmd.none
        , outputs = []
        }


type alias ReturnF mod msg out a =
    a -> Return mod msg out


returnModel : ReturnF mod msg out (ModelModifier mod)
returnModel =
    returnWithSomething withModel


returnCmd : ReturnF mod msg out (Cmd msg)
returnCmd =
    returnWithSomething withCmd


returnOutput : ReturnF mod msg out out
returnOutput =
    returnWithSomething withOutput


returnOutputs : ReturnF mod msg out (List out)
returnOutputs =
    returnWithSomething withOutputs



---- Helper


returnWithSomething : WithF mod msg out a -> ReturnF mod msg out a
returnWithSomething with a =
    returnNothing
        |> with a



-- Merge: Making multiple Returns into a single Return


type alias Merge a =
    a -> a -> a


mergeMaybeModel : Merge (Maybe (ModelModifier mod))
mergeMaybeModel m1 m2 =
    case ( m1, m2 ) of
        ( Just m1_, Just m2_ ) ->
            Just <| m1_ >> m2_

        ( Just _, Nothing ) ->
            m1

        ( Nothing, Just _ ) ->
            m2

        _ ->
            Nothing


mergeCmd : Merge (Cmd msg)
mergeCmd c1 c2 =
    Cmd.batch [ c1, c2 ]


pushOutput : out -> List out -> List out
pushOutput o os =
    os ++ [ o ]


mergeOutputs : Merge (List out)
mergeOutputs o1 o2 =
    o1 ++ o2


merge : Merge (Return mod msg out)
merge (Return r1) (Return r2) =
    Return
        { modelModifierM = mergeMaybeModel r1.modelModifierM r2.modelModifierM
        , cmd = mergeCmd r1.cmd r2.cmd
        , outputs = mergeOutputs r1.outputs r2.outputs
        }


mergeAll : List (Return mod msg out) -> Return mod msg out
mergeAll =
    List.foldl merge returnNothing



-- Transform and map


transformModel : (mod_ -> mod) -> (mod_ -> mod -> mod_) -> Return mod msg out -> Return mod_ msg out
transformModel from to (Return { modelModifierM, cmd, outputs }) =
    Return
        { modelModifierM = Maybe.map (\mf -> \m_ -> from m_ |> mf |> to m_) modelModifierM
        , cmd = cmd
        , outputs = outputs
        }


mapCmd : (msg -> msg_) -> Return mod msg out -> Return mod msg_ out
mapCmd f (Return { modelModifierM, cmd, outputs }) =
    Return
        { modelModifierM = modelModifierM
        , cmd = Cmd.map f cmd
        , outputs = outputs
        }


mapOutputs : (out -> out_) -> Return mod msg out -> Return mod msg out_
mapOutputs f (Return { modelModifierM, cmd, outputs }) =
    Return
        { modelModifierM = modelModifierM
        , cmd = cmd
        , outputs = List.map f outputs
        }



-- Use Return


applyModel : Return mod msg out -> mod -> mod
applyModel =
    asModelModifier >> Maybe.withDefault identity


handleOutputs : (out -> Return mod msg out) -> Return mod msg out -> Return mod msg out
handleOutputs handle ((Return { outputs }) as return) =
    List.foldl (\o r -> handle o |> merge r) return outputs


clearOutputs : Return mod msg out -> Return mod msg out_
clearOutputs (Return r) =
    Return
        { modelModifierM = r.modelModifierM
        , cmd = r.cmd
        , outputs = []
        }

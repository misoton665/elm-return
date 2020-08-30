module Return exposing
    ( Return
    , applyModel
    , asModelModifier
    , asCmd
    , asOutputs
    , clearOutputs
    , consumeOutputs
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

{-| This package proposes a Return type that helps building a structure for scalable programming on TEA.

# Definition
@docs Return

# Getting a value
@docs asModelModifier, asCmd, asOutputs

# Generating a Return value
@docs returnModel, returnCmd, returnOutput, returnOutputs, returnNothing

# Decorating a generated Return.
@docs withModel, withCmd, withOutput, withOutputs

# Transforming and mapping
@docs transformModel, mapCmd, mapOutputs

# Merging multiple Returns into a single Return
@docs merge, mergeAll

# Using a Return value
@docs applyModel, handleOutputs, clearOutputs, consumeOutputs
-}

{-|
An alternative type to (Model, Cmd msg), which is the return value of the general update function.

```elm
-- before
update : Msg -> Model -> (Model, Cmd Msg)

-- after
update : Msg -> Return Model Msg Output
```
-}

type Return model msg output
    = Return
        { modelModifierM : Maybe (ModelModifier model)
        , cmd : Cmd msg
        , outputs : List output
        }


{-| Function to update the value of Model.
-}
type alias ModelModifier mod =
    mod -> mod



-- Get

{-| Convert to ModelModifier
-}
asModelModifier : Return mod msg out -> Maybe (ModelModifier mod)
asModelModifier (Return { modelModifierM }) =
    modelModifierM

{-| Convert to Cmd
-}
asCmd : Return mod msg out -> Cmd msg
asCmd (Return { cmd }) =
    cmd

{-| Convert to Outputs
-}
asOutputs : Return mod msg out -> List out
asOutputs (Return { outputs }) =
    outputs



-- With: Decorate a generated Return.


type alias WithF mod msg out a =
    a -> Return mod msg out -> Return mod msg out

{-| Add a ModelModifier to the return
-}
withModel : WithF mod msg out (ModelModifier mod)
withModel model (Return r) =
    Return { r | modelModifierM = mergeMaybeModel r.modelModifierM (Just model) }

{-| Add a Cmd to the return
-}
withCmd : WithF mod msg out (Cmd msg)
withCmd cmd_ (Return r) =
    Return { r | cmd = mergeCmd r.cmd cmd_ }

{-| Add a Output to the return
-}
withOutput : WithF mod msg out out
withOutput output (Return r) =
    Return { r | outputs = pushOutput output r.outputs }

{-| Add Output list to the return
-}
withOutputs : WithF mod msg out (List out)
withOutputs outputs_ (Return r) =
    Return { r | outputs = mergeOutputs r.outputs outputs_ }



-- Generate Return

{-| Generate an empty Return.
-}
returnNothing : Return mod msg out
returnNothing =
    Return
        { modelModifierM = Nothing
        , cmd = Cmd.none
        , outputs = []
        }


type alias ReturnF mod msg out a =
    a -> Return mod msg out

{-| Generate a Return having a ModelModifier.
-}
returnModel : ReturnF mod msg out (ModelModifier mod)
returnModel =
    returnWithSomething withModel

{-| Generate a Return having a Cmd.
-}
returnCmd : ReturnF mod msg out (Cmd msg)
returnCmd =
    returnWithSomething withCmd

{-| Generate a Return having a Output.
-}
returnOutput : ReturnF mod msg out out
returnOutput =
    returnWithSomething withOutput

{-| Generate a Return having Output list.
-}
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

{-| Merge two Returns into a one Return.
-}
merge : Merge (Return mod msg out)
merge (Return r1) (Return r2) =
    Return
        { modelModifierM = mergeMaybeModel r1.modelModifierM r2.modelModifierM
        , cmd = mergeCmd r1.cmd r2.cmd
        , outputs = mergeOutputs r1.outputs r2.outputs
        }

{-| Merge multiple Returns into a one Return.
-}
mergeAll : List (Return mod msg out) -> Return mod msg out
mergeAll =
    List.foldl merge returnNothing



-- Transform and map

{-| Transform a model type to the other.
-}
transformModel : (after -> before) -> (after -> before -> after) -> Return before msg out -> Return after msg out
transformModel from to (Return { modelModifierM, cmd, outputs }) =
    let
        toTransformedModelModifier beforeModifier afterModel =
            from afterModel
                |> beforeModifier
                |> to afterModel
    in
    Return
        { modelModifierM = Maybe.map toTransformedModelModifier modelModifierM
        , cmd = cmd
        , outputs = outputs
        }

{-| Map a Cmd in a Return.
-}
mapCmd : (msg -> msg_) -> Return mod msg out -> Return mod msg_ out
mapCmd f (Return { modelModifierM, cmd, outputs }) =
    Return
        { modelModifierM = modelModifierM
        , cmd = Cmd.map f cmd
        , outputs = outputs
        }

{-| Map Outputs in a Return.
-}
mapOutputs : (out -> out_) -> Return mod msg out -> Return mod msg out_
mapOutputs f (Return { modelModifierM, cmd, outputs }) =
    Return
        { modelModifierM = modelModifierM
        , cmd = cmd
        , outputs = List.map f outputs
        }



-- Use Return


{-| Apply a Model to ModelModifier.
-}
applyModel : Return mod msg out -> mod -> mod
applyModel =
    asModelModifier >> Maybe.withDefault identity

{-| Reflects the Output in the Return.
the Return returned by the handle function is merged with the original Return.
-}
handleOutputs : (out -> Return mod msg out) -> Return mod msg out -> Return mod msg out
handleOutputs handle ((Return { outputs }) as return) =
    List.foldl (\o r -> handle o |> merge r) return outputs

{-| Make outputs empty.
-}
clearOutputs : Return mod msg out -> Return mod msg out_
clearOutputs (Return r) =
    Return
        { modelModifierM = r.modelModifierM
        , cmd = r.cmd
        , outputs = []
        }

{-| Handle outputs then clear it.
-}
consumeOutputs : (out -> Return mod msg out) -> Return mod msg out -> Return mod msg out_
consumeOutputs handle =
    handleOutputs handle >> clearOutputs
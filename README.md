# elm-return

This repository proposes a Return type that builds a structure for scalable programming on TEA.

## Return

An alternative type to (Model, Cmd msg), which is the return value of the general update function.

```elm
-- before
update : Msg -> Model -> (Model, Cmd Msg)

-- after
update : Msg -> Return Model Msg Output
```

You may have noticed that the Model is missing from the argument; the Model argument is not required if the update function returns Return type.

The Output type is also new. We'll get to that later.

Using Return changes the way the update function is written.

```elm
-- before
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChildModuleMsg childMsg ->
            let
                ( childModel, childCmd ) =
                    ChildModule.update childMsg model.childModel
            in
            ( { model | childModel = childModel }
            , Cmd.map ChildModuleMsg childCmd
            )
        
        ButtonClicked ->
            ( { model | count = model.count + 1 }
            , Cmd.none
            )

-- after
update : Msg -> Return Model Msg output
update msg =
    case msg of
        ChildModuleMsg childMsg ->
            ChildModule.update childMsg
                |> transformFromChild

        ButtonClicked ->
            returnModel
                (\model -> { model | count = model.count + 1 }
                )
```

The purpose of using elm-return is to be more declarative, shorter, and to make it easier to connect or separate modules.

The concept of Output is related to connect modules.

TEA does not define a concrete way to connect modules.
In elm-return, we define this structurally by introducing Output.

Output is, in a word, Msg from one module to another.

When there is a parent-child relationship between modules, Output is defined by the child module and interpreted by the parent module.
In order to separate interests, Output should be written in the word of the child modules.
```elm
-- Child module
type Output
    = Submitted


update : Msg -> Return Model Msg Output
update msg =
    -- ...

    FormButtonClicked ->
        returnOutput Submitted
```

```elm
-- Parent module
update : Msg -> Return Model Msg Output
update msg =
    case msg of
        -- ...

        ChildModuleMsg childMsg ->
            ChildModule.update childMsg
                |> transformFromChildModule
                |> consumeOutput handleChildModuleOutput


handleChildModuleOutput : ChildModule.Output -> Return Model Msg output
handleChildModuleOutput output =
    case output of
        ChildModule.Submitted ->
            returnCmd submit
```

The return type is defined as follows.

```elm
type Return model msg output
    = Return
        { modelModifierM : Maybe (ModelModifier model)
        , cmd : Cmd msg
        , outputs : List output
        }

type alias ModelModifier mod =
    mod -> mod
```

model, msg, and output are all mappable, and multiple returns can be merged into a single return. (As for the model, it's not strictly a mapping.)

These functions help with declarative statements.

---

This is inspired by:
  - https://github.com/Fresheyeball/elm-return
  - https://github.com/purescript-halogen/purescript-halogen
  - A talk by @jinjor at the Elm meetup at Fringe81; https://fringeneer.hatenablog.com/entry/2019/09/06/135624 (You won't find the slide on this site.)

All texts have been translated using DeepL 😉.

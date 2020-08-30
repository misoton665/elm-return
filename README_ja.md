# elm-return

elm-returnはReturn型を提供することでスケーラブルなモジュールの作成をお手伝いします。

## Return

Return型はupdate関数の一般的な戻り値である(Model, Cmd msg)型の代替になる型です。

```elm
-- before
update : Msg -> Model -> ( Model, Cmd Msg )

-- after
update : Msg -> Return Model Msg Output
```

引数からModelがなくなったことに気がつきましたか？update関数でReturn型を返す場合、引数のModelは必須ではありません。

Output型も新しく登場しています。これについては後ほど説明します。

Returnを使うとupdate関数の書き方が少し変わります。

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

より宣言的で、短く、モジュール同士を簡単に結合もしくは分離できるようにすることがelm-returnを使用する目的です。

モジュール同士の結合に関わるのがOutputの概念です。

TEAにはモジュール同士を結合する具体的な方法は定められていません。
elm-returnではOutputを導入することで構造的にこれを定めます。

Outputは一言で言うとあるモジュールから他のモジュールへ向けたMsgです。

モジュール間に親子関係があった場合、Outputは子モジュールが定義し、親モジュールが解釈します。
関心ごとを分離するためにOutputは子モジュールの言葉で書かれているべきでしょう。

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

Return型は以下のように定義されています。

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

ModelModifier model、msg、outputはいずれもマッピング可能で、複数の同じReturnは1つのReturnにマージ可能です。
それらの関数が宣言的な記述の補助をします。

---

影響されたもの:
  - https://github.com/Fresheyeball/elm-return
  - https://github.com/purescript-halogen/purescript-halogen
  - Fringe81で行われたElm meetupでの@jinjorさんによるトーク; https://fringeneer.hatenablog.com/entry/2019/09/06/135624 (リンク先に該当のスライドはありません)

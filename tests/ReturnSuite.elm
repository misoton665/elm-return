module ReturnSuite exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import Support.Return as Return


type Output
    = A
    | B


type alias ModelA = Int


type alias ModelB =
    { modelA : ModelA
    }


suite : Test
suite =
    describe "Return"
        [ test "Simple merge" <|
            \_ ->
                let
                    a =
                        Return.returnModel ((+) 1)
                            |> Return.withOutput A

                    b =
                        Return.returnModel ((*) 3)
                            |> Return.withOutput B

                    merged =
                        Return.merge a b
                in
                Expect.equal (Return.applyModel merged 0, Return.asOutputs merged) (3, [ A, B ])

        , test "Simple merge reverse" <|
            \_ ->
                let
                    a =
                        Return.returnModel ((+) 1)
                            |> Return.withOutput A

                    b =
                        Return.returnModel ((*) 3)
                            |> Return.withOutput B

                    merged =
                        Return.merge b a
                in
                Expect.equal (Return.applyModel merged 0, Return.asOutputs merged) (1, [ B, A ])

        , test "simple transformModel" <|
           \_ ->
            let
                a =
                    Return.returnModel ((+) 1)

                init =
                    { modelA = 0
                    }

                transformed =
                    Return.transformModel .modelA (\model m -> { model | modelA = m }) a
            in
            Expect.equal (Return.applyModel transformed init) ({ modelA = 1 })

        , test "transformModel and merge" <|
           \_ ->
            let
                a =
                    Return.returnModel ((+) 1)

                b =
                    Return.returnModel ((*) 3)

                init =
                    { modelA = 0
                    }

                transformedA =
                    Return.transformModel .modelA (\model m -> { model | modelA = m }) a

                transformedB =
                    Return.transformModel .modelA (\model m -> { model | modelA = m }) b

                merged =
                    Return.merge transformedA transformedB
            in
            Expect.equal (Return.applyModel merged init) ({ modelA = 3 })
        ]

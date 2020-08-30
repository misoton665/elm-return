module Messages exposing (Messages, asList, empty, push)


type Messages
    = Messages (List String)


empty : Messages
empty =
    Messages []


push : String -> Messages -> Messages
push m (Messages ms) =
    Messages <| m :: ms


asList : Messages -> List String
asList (Messages ms) =
    ms

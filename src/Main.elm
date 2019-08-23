module Main exposing (main)

import Browser
import Html exposing (Html, div, text)

main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }


type alias Model =
    String


init : Model
init =
    "Hello world"


type Msg
    = NoOp


update : Msg -> Model -> Model
update msg model =
    model


view : Model -> Html msg
view model =
    div
        []
        [ text model ]

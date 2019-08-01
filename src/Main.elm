module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, div, text, img)
import Html.Attributes exposing (href, style, class, src)
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, oneOf, s, top)


main =
    Browser.application
        { init = init
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Model =
    { key : Nav.Key
    , page : Page
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( initialModel url key, Cmd.none )


initialModel : Url.Url -> Nav.Key -> Model
initialModel url key =
    { key = key
    , page = urlToPage url
    }


type Page
    = NotFound
    | Home


urlToPage : Url.Url -> Page
urlToPage url =
    Parser.parse parser url
        |> Maybe.withDefault NotFound


parser : Parser (Page -> a) a
parser =
    oneOf
        [ Parser.map Home top
        ]


type Msg
    = NoOp
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | page = urlToPage url }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "Samhstn"
    , body = body model
    }


body : Model -> List (Html Msg)
body model =
    [ div
        [ class "background-box" ]
        [ img
            [ class "logo"
            , src "/static/images/logo.png"
            ]
            []
        ]
    ]

module Example01 exposing (main)

import Html exposing (div, text)
import Html.Attributes exposing (style)
import Json.Decode exposing (Value)
import Json.Encode
import MapCommands
import Mapbox.Element exposing (..)
import Mapbox.Expression as E exposing (false, float, int, str, true)
import Mapbox.Layer as Layer
import Mapbox.Source as Source
import Mapbox.Style as Style exposing (Style(..))


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \m -> Sub.none
        }


init =
    ( { position = ( 0, 0 ), selectedFeatures = [] }, Cmd.none )


type Msg
    = Hover EventData
    | Click EventData


mapPair f ( a, b ) =
    ( f a, f b )


update msg model =
    case msg of
        Hover { lngLat, renderedFeatures } ->
            ( { model | position = lngLat, selectedFeatures = renderedFeatures }, Cmd.none )

        Click { lngLat } ->
            ( model, MapCommands.fitBounds [ MapCommands.linear True ] ( mapPair (\a -> a - 0.2) lngLat, mapPair (\a -> a + 0.2) lngLat ) )


view model =
    div [ style [ ( "width", "100vw" ), ( "height", "100vh" ) ] ]
        [ css
        , map
            [ maxZoom 5
            , onMouseMove Hover
            , onClick Click
            , id "my-map"
            , model.selectedFeatures
                |> List.map (\f -> ( f, [ ( "hover", Json.Encode.bool True ) ] ))
                |> featureState
            ]
            (Style
                { transition = Style.defaultTransition
                , light = Style.defaultLight
                , sources =
                    [ Source.vectorFromUrl "composite" "mapbox://mapbox.mapbox-terrain-v2,mapbox.mapbox-streets-v7,astrosat.07pz1g3y" ]
                , misc =
                    [ Style.name "light"
                    , Style.defaultCenter 20.39789404164037 43.22523201923144
                    , Style.defaultZoomLevel 1.5967483759772743
                    , Style.sprite "mapbox://sprites/astrosat/cjht22eqw0lfc2ro6z0qhlm29"
                    , Style.glyphs "mapbox://fonts/astrosat/{fontstack}/{range}.pbf"
                    ]
                , layers =
                    [ Layer.background "background"
                        [ E.rgba 246 246 244 1 |> Layer.backgroundColor
                        ]
                    , Layer.fill "landcover"
                        "composite"
                        [ Layer.sourceLayer "landcover"
                        , E.any
                            [ E.getProperty (str "class") |> E.isEqual (str "wood")
                            , E.getProperty (str "class") |> E.isEqual (str "scrub")
                            , E.getProperty (str "class") |> E.isEqual (str "grass")
                            , E.getProperty (str "class") |> E.isEqual (str "crop")
                            ]
                            |> Layer.filter

                        -- , Layer.fillColor (E.rgba 227 227 227 1)
                        , Layer.fillColor (E.ifElse (E.coalesce [ (E.featureState (str "hover")), false ]) (E.rgba 20 227 227 1) (E.rgba 227 227 227 1))
                        , Layer.fillOpacity (float 0.6)
                        ]
                    ]
                }
            )
        , div [ style [ ( "position", "absolute" ), ( "bottom", "20px" ), ( "left", "20px" ) ] ] [ text (toString model.position) ]
        ]

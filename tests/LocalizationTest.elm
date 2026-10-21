module LocalizationTest exposing (suite)

import Expect
import Locale exposing (Locale(..))
import Localization exposing (LoadKind(..), Notice(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "translation request state"
        [ test "starts a request with a new generation" <|
            \_ ->
                let
                    ( state, request ) =
                        Localization.start Startup SimplifiedChinese Localization.initial
                in
                Expect.equal ( 1, Just request ) ( state.generation, Localization.pending state )
        , test "accepts only the latest request" <|
            \_ ->
                let
                    ( firstState, first ) =
                        Localization.start Switch SimplifiedChinese Localization.initial

                    ( latestState, latest ) =
                        Localization.start Switch TraditionalChinese firstState
                in
                Expect.all
                    [ \_ -> Expect.equal (Err Localization.Superseded) (Localization.accept first latestState)
                    , \_ -> Expect.equal (Ok ()) (Result.map (\_ -> ()) (Localization.accept latest latestState))
                    ]
                    ()
        , test "successful switch changes the notice" <|
            \_ ->
                let
                    ( state, request ) =
                        Localization.start Switch TraditionalChinese Localization.initial
                in
                case Localization.accept request state of
                    Err _ ->
                        Expect.fail "latest request should be accepted"

                    Ok accepted ->
                        Expect.equal ( Changed TraditionalChinese, Nothing ) ( accepted.notice, accepted.failedTarget )
        , test "failed switch keeps a retry target" <|
            \_ ->
                let
                    ( state, request ) =
                        Localization.start Switch SimplifiedChinese Localization.initial
                in
                case Localization.fail request state of
                    Err _ ->
                        Expect.fail "latest request should be rejected once"

                    Ok failed ->
                        Expect.equal ( Failed SimplifiedChinese, Just SimplifiedChinese ) ( failed.notice, failed.failedTarget )
        , test "successful English fallback preserves the requested locale" <|
            \_ ->
                let
                    ( started, failedRequest ) =
                        Localization.start Startup TraditionalChinese Localization.initial

                    failed =
                        Localization.fail failedRequest started |> Result.toMaybe

                    ( fallback, fallbackRequest ) =
                        Localization.start (Fallback TraditionalChinese) English (Maybe.withDefault Localization.initial failed)
                in
                case Localization.accept fallbackRequest fallback of
                    Err _ ->
                        Expect.fail "fallback should be accepted"

                    Ok accepted ->
                        Expect.equal ( FallbackNotice TraditionalChinese, Just TraditionalChinese ) ( accepted.notice, accepted.failedTarget )
        ]

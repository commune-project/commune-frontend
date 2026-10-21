module LocaleTest exposing (suite)

import Expect
import Locale exposing (Locale(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "locale negotiation"
        [ test "preserves exact public identifiers" <|
            \_ ->
                Expect.equal
                    [ "en-US", "zh-cmn-Hans-CN", "zh-cmn-Hant-TW" ]
                    (List.map Locale.code Locale.all)
        , test "saved preference wins over browser preferences" <|
            \_ ->
                Expect.equal TraditionalChinese (Locale.negotiate (Just "zh-cmn-Hant-TW") [ "en-US" ])
        , test "uses the first supported browser language" <|
            \_ ->
                Expect.equal SimplifiedChinese (Locale.negotiate Nothing [ "fr-FR", "zh-CN", "en-US" ])
        , test "falls back to English" <|
            \_ ->
                Expect.equal English (Locale.negotiate Nothing [ "fr-FR", "de-DE" ])
        , test "favors an explicit Traditional script" <|
            \_ ->
                Expect.equal (Just TraditionalChinese) (Locale.match "cmn-Hant-CN")
        , test "maps bare Chinese to Simplified" <|
            \_ ->
                Expect.equal (Just SimplifiedChinese) (Locale.match "zh")
        , test "uses interoperable Intl identifiers" <|
            \_ ->
                Expect.equal "zh-Hans-CN" (Locale.formattingLocale SimplifiedChinese)
        ]

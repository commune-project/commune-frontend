module RichTest exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Ui.Rich


suite : Test
suite =
    describe "safe display URLs"
        [ test "accepts relative and web URLs" <|
            \_ ->
                Expect.equal [ True, True, True, True ]
                    (List.map Ui.Rich.safeUrl [ "/api/v1/media/a", "#section", "https://example.test/a", "http://example.test/a" ])
        , test "rejects executable and ambiguous URLs" <|
            \_ ->
                Expect.equal [ False, False, False, False, False ]
                    (List.map Ui.Rich.safeUrl [ "javascript:alert(1)", "data:text/html,x", "//evil.test/a", "/\\evil.test", "https://example.test/a\\b" ])
        ]

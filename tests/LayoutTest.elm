module LayoutTest exposing (suite)

import App.Layout exposing (applyLayout)
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "navigation drawer layout"
        [ test "a wide viewport opens the permanent drawer" <|
            \_ ->
                Expect.equal { wideLayout = True, drawerOpen = True }
                    (applyLayout True { wideLayout = False, drawerOpen = False })
        , test "a compact viewport closes the modal drawer" <|
            \_ ->
                Expect.equal { wideLayout = False, drawerOpen = False }
                    (applyLayout False { wideLayout = True, drawerOpen = True })
        , test "reapplying the current mode keeps the reader's drawer choice" <|
            \_ ->
                Expect.equal { wideLayout = True, drawerOpen = False }
                    (applyLayout True { wideLayout = True, drawerOpen = False })
        ]

module App.Layout exposing (Layout, applyLayout)


type alias Layout =
    { wideLayout : Bool
    , drawerOpen : Bool
    }


applyLayout : Bool -> Layout -> Layout
applyLayout wide layout =
    if wide == layout.wideLayout then
        layout

    else
        { wideLayout = wide
        , drawerOpen = wide
        }

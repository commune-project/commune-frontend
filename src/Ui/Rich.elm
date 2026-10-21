module Ui.Rich exposing (safeUrl, view)

import Html exposing (Html)
import Html.Attributes as A
import Html.Parser as Parser


safeUrl : String -> Bool
safeUrl value =
    let
        lower =
            String.toLower (String.trim value)
    in
    not (String.any (\c -> Char.toCode c < 32 || c == '\\') value)
        && ((String.startsWith "/" lower && not (String.startsWith "//" lower)) || String.startsWith "https://" lower || String.startsWith "http://" lower || String.startsWith "#" lower)


view : String -> Html msg
view source =
    case Parser.run source of
        Ok nodes ->
            Html.div [ A.class "rich", A.dir "auto" ] (List.map render nodes)

        Err _ ->
            Html.div [ A.class "rich", A.dir "auto" ] [ Html.text source ]


render : Parser.Node -> Html msg
render node =
    case node of
        Parser.Text value ->
            Html.text value

        Parser.Comment _ ->
            Html.text ""

        Parser.Element name attributes children ->
            let
                allowed =
                    List.member name [ "p", "br", "strong", "em", "del", "blockquote", "pre", "code", "ul", "ol", "li", "h1", "h2", "h3", "h4", "h5", "h6", "a", "img", "hr", "table", "thead", "tbody", "tr", "th", "td", "span", "bdi" ]

                attr ( key, value ) =
                    if (key == "href" && name == "a" || key == "src" && name == "img") && safeUrl value then
                        Just (A.attribute key value)

                    else if key == "alt" || key == "title" || key == "lang" || key == "dir" && List.member value [ "auto", "ltr", "rtl" ] then
                        Just (A.attribute key value)

                    else
                        Nothing

                tag =
                    case name of
                        "h1" ->
                            "h2"

                        _ ->
                            name

                extra =
                    if name == "img" then
                        [ A.attribute "referrerpolicy" "no-referrer", A.attribute "loading" "lazy", A.alt (List.filter (Tuple.first >> (==) "alt") attributes |> List.head |> Maybe.map Tuple.second |> Maybe.withDefault "") ]

                    else if name == "a" then
                        [ A.rel "noopener noreferrer" ]

                    else
                        []
            in
            if allowed then
                Html.node tag (extra ++ List.filterMap attr attributes) (List.map render children)

            else
                Html.text ""

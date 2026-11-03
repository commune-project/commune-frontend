module VoteControlTest exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Ui.VoteControl as VoteControl


suite : Test
suite =
    describe "merged vote direction visibility"
        [ test "offers both enabled directions" <|
            \_ ->
                Expect.equal { showUp = True, showDown = True }
                    (VoteControl.visibility { canUpvote = True, canDownvote = True, canLike = True, votedByMe = 0 })
        , test "uses the like alias for upvote when needed" <|
            \_ ->
                Expect.equal { showUp = True, showDown = False }
                    (VoteControl.visibility { canUpvote = False, canDownvote = False, canLike = True, votedByMe = 0 })
        , test "keeps an existing disabled direction clearable" <|
            \_ ->
                Expect.equal [ { showUp = True, showDown = False }, { showUp = False, showDown = True } ]
                    [ VoteControl.visibility { canUpvote = False, canDownvote = False, canLike = False, votedByMe = 1 }
                    , VoteControl.visibility { canUpvote = False, canDownvote = False, canLike = False, votedByMe = -1 }
                    ]
        ]

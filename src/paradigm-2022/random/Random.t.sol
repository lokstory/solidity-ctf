// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Setup.sol";

contract RandomTest is Test {
    Setup internal _setup;

    function setUp() public {
        _setup = new Setup();
    }

    function test_attack() public {
        Random random = _setup.random();

        random.solve(4);

        assertTrue(_setup.isSolved());
    }
}
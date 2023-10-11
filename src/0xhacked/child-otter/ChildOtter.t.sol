// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./ChildOtter.sol";

contract ChildOtterTest is Test {
    ChildOtter internal _otter;

    function setUp() public {
        _otter = new ChildOtter();
    }

    function test_exploit() public {
        // slot: 0
        // keccak256(0, keccak256(0, 0))
        _otter.solve(uint256(keccak256(abi.encode(0, 0))));
    }
}
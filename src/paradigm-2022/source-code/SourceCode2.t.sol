// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./SourceCode2.sol";

contract SourceCode2Test is Test {
    Challenge internal _challenge;

    function setUp() public {
        _challenge = new Challenge();
    }

    function test_attack() public {
        bytes memory prefix = hex"7f";

        bytes memory suffix = bytes.concat(
            // padding   : 32 - 25 = 7 bytes
            //
            // 1. Fill suffix to 32 bytes by any meaningless op codes
            //
            // PUSH5 0x0000000000
            // POP
            hex"64_0000000000_50",
            // code      : 25 bytes
            //
            // 2. Copy suffix
            //
            // DUP1
            hex"80",
            // 3. Store suffix to memory [32:64]
            //
            // PUSH1 0x20
            // MSTORE
            hex"60_20_52",
            // 4. Store suffix to memory [64:96]
            //
            // PUSH1 0x40
            // MSTORE
            hex"60_40_52",
            // 5. Store 0x7f to memory [31]
            //
            // PUSH1 0x7f
            // PUSH1 0x1f
            // MSTORE8
            hex"60_7f_60_1f_53",
            // 6. keccak256 from memory [31:96] and the size is 65
            //
            // PUSH1 0x41
            // PUSH1 0x1f
            // SHA3
            hex"60_41_60_1f_20",
            // 6. Store the hash value to memory [0:32]
            //
            // PUSH1 0x00
            // MSTORE
            hex"60_00_52",
            // 6. Return memory [0:32]
            //
            // PUSH1 0x20
            // PUSH1 0x00
            // RETURN
            hex"60_20_60_00_f3"
        );

        // PUSH32 suffix
        // suffix
        bytes memory code = bytes.concat(prefix, suffix, suffix);

        _challenge.solve(code);

        assertTrue(_challenge.solved());
    }
}
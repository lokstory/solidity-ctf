// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Setup.sol";

contract SourceCodeTest is Test {
    Setup internal _setup;

    function setUp() public {
        _setup = new Setup();
    }

    function test_attack() public {
        // 0x30 - 0x48 are invalid
        // 30 ADDRESS
        // 31 BALANCE
        // 32 ORIGIN
        // 33 CALLER
        // 34 CALLVALUE
        // 35 CALLDATALOAD
        // 36 CALLDATASIZE
        // 37 CALLDATACOPY
        // 38 CODESIZE
        // 39 CODECOPY
        // 3A GASPRICE
        // 3B EXTCODESIZE
        // 3C EXTCODECOPY
        // 3D RETURNDATASIZE
        // 3E RETURNDATACOPY
        // 3F EXTCODEHASH
        // 40 BLOCKHASH
        // 41 COINBASE
        // 42 TIMESTAMP
        // 43 NUMBER
        // 44 PREVRANDAO
        // 45 GASLIMIT
        // 46 CHAINID
        // 47 SELFBALANCE
        // 48 BASEFEE

        // Cannot use CODECOPY
        // code = prefix + suffix + suffix

        // PUSH32
        bytes memory prefix = hex"7f";

        bytes memory suffix = bytes.concat(
            // code      : 17 bytes
            //
            // 1. Copy suffix
            //
            // DUP1
            hex"80",
            // 2. Store suffix to memory [32:64]
            //
            // PUSH1 0x20
            // MSTORE
            hex"60_20_52",
            // 3. Store suffix to memory [64:96]
            //
            // PUSH1 0x40
            // MSTORE
            hex"60_40_52",
            // 4. Store 0x7f to memory [31]
            //
            // PUSH1 0x7f
            // PUSH1 0x1f
            // MSTORE8
            hex"60_7f_60_1f_53",
            // 5. Return memory [31:96] and the size is 65
            //
            // PUSH1 0x41
            // PUSH1 0x1f
            // RETURN
            hex"60_41_60_1f_f3",
            // padding   : 32 - 17 = 15 bytes
            //
            // 6. Fill suffix to 32 bytes by any meaningless op codes
            //
            // STOP
            hex"000000000000000000000000000000"
            // JUMPDEST
//            hex"5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B"
            // RETURN
//            hex"F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3"
            // INVALID
//            hex"FEFEFEFEFEFEFEFEFEFEFEFEFEFEFE"
        );

        // PUSH32 suffix
        // suffix
        bytes memory code = bytes.concat(prefix, suffix, suffix);

        Challenge challenge = _setup.challenge();
        challenge.solve(code);

        assertTrue(_setup.isSolved());
    }
}
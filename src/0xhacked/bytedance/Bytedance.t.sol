// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Bytedance.sol";

contract Attacker {
    constructor(Bytedance dance_) {
        dance_.setup();

        bytes memory code;

        code = bytes.concat(
            // 1. abi.encodePacked("Hello Player")
            // 48_65_6c6c6f20506c_61_7965_72
            // BASEFEE
            // PUSH6 6c6c6f20506c
            // PUSH2 7695
            // PUSH19
            //
            // Value of PUSH19
            // length: 19 bytes
            hex"00000000000000000000000000000000000000",
            // Return "48656c6c6f20506c61796572" for 1
            // length: 12 bytes
            // PUSH1 0c
            // PUSH1 00
            // PUSH1 00
            // codecopy(0, 0, 12)
            // PUSH1 0c
            // PUSH1 00
            // return(0, 12)
            hex"60_0c_60_00_60_00_39_60_0c_60_00_f3",
            // 2. abi.encodePacked("`*V")
            // length: 3 bytes
            // 60_2a_56
            // PUSH1 2a
            // JUMP to 42
            //
            // prefix: 3 + 19 + 12 = 34 bytes
            // Add JUMPDEST at the 43th byte
            hex"00_00_00_00_00_00_00_00_5b",
            // Return "602a56" for 2
            //
            // PUSH1 03
            // PUSH1 00
            // PUSH1 00
            // codecopy(0, 0, 3)
            // PUSH1 03
            // PUSH1 00
            // return(0, 3)
            hex"60_03_60_00_60_00_39_60_03_60_00_f3"
        );

        assembly {
            return (add(code, 32), mload(code))
        }
    }
}

contract BytedanceTest is Test {
    Bytedance internal _dance;

    function setUp() public {
        _dance = new Bytedance();
    }

    function test_exploit() public {
        new Attacker(_dance);

        _dance.solve();

        assertTrue(_dance.solved(), "solved");
    }
}
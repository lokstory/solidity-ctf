// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./ByteDance.sol";

/// https://github.com/MetaTrustLabs/ctf/blob/master/byteDance/contracts/byteDance.sol

contract Metamorphic {
    fallback(bytes calldata) external returns (bytes memory code) {
        // Conditions:
        // 1. Every bytes1 must be odd (uint8(b) % 2 == 1)
        // 2. Any one bytes1 of code must is byte dance
        //
        // Byte dance list:
        // 0          : STOP
        // 24   (18)  : XOR
        // 36   (24)  :
        // 60   (3C)  : EXTCODECOPY
        // 66   (42)  : TIMESTAMP
        // 90   (5A)  : GAS
        // 102  (66)  : PUSH7
        // 126  (7E)  :
        // 129  (81)  : DUP2
        // 153  (99)  : SWAP10
        // 165  (A5)  :
        // 189  (BD)  :
        // 195  (C3)  :
        // 219  (DB)  :
        // 231  (E7)  :
        // 255  (FF)  : SELFDESTRUCT

        // solved slot: 0
        //      (55)  : SSTORE
        //      (03)  : SUB
        //
        // PUSH1 0101
        // PUSH1 0101
        // DUP2
        // SUB
        // SSTORE
        //
        // sstore(1 - 1, 1)
        code = hex"610101_610101_81_03_55";
    }
}

contract ByteDanceTest is Test {
    ByteDance internal _dance;

    function setUp() public {
        _dance = new ByteDance();
    }

    function test_attack() public {
        bytes memory code = type(Metamorphic).runtimeCode;
        address addr;

        assembly {
            addr := create(0, add(code, 0x20), mload(code))
        }

        _dance.checkCode(addr);

        assertTrue(_dance.isSolved());
    }
}

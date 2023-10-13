// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Snakes.sol";

contract SnakesTest is Test {
    Snakes internal _snakes;

    function setUp() public {
        _snakes = new Snakes();
    }

    function test_attack() public {
        // 60_00_35_60_e0_1c_60_02_60_0c_82_06_60_01_1b_61_06_b1_01_60_1e_39_60_00_51_56
        //
        // PUSH1 0
        // CALLDATALOAD
        //
        // 1. a = Load first 32 bytes (array length) from call data
        //
        // PUSH1 e0
        // SHR
        //
        // 2. b = a >> 224 = pick left 4 bytes
        //
        // PUSH1 02
        // PUSH1 0c
        // DUP3
        // MOD
        //
        // 3. c = b % 12
        //
        // PUSH1 01
        // SHL
        //
        // 4. d = c << 1
        //
        // PUSH2 06b1
        // ADD
        //
        // 5. e = 1713 + d
        //
        // PUSH1 1e
        // CODECOPY
        //
        // 6. f = codecopy(30, e, 2)
        // bytecode from 1713: 
        // 040b06a506a506a506a5055a047c06a50329039a001a06380000000000000000000000000000000000000000000000
        // copy 2 bytes from above bytecode to memory 30 - 31 bytes
        //
        // PUSH1 00
        // MLOAD
        // JUMP
        // 7. Jump to f
        //
        // Available JUMPDEST list:
        // 1a  : d = 20 (001a), c = 10
        // 329 : d = 16 (0329), c = 8
        // 39a : d = 18 (039a), c = 9
        // 40b : d = 0  (040b), c = 0
        // 47c : d = 12 (047c), c = 6
        // 55a : d = 10 (055a), c = 5
        // 638 : d = 22 (0638), c = 11
        // 6a5 : d = 2, 4, 6, 8, 14, c = 1, 2, 3, 4, 7

        bytes memory data = abi.encode(0);

        _snakes.solve(data);

        assertTrue(_snakes.solved());
    }
}
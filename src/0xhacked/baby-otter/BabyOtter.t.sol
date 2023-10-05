// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BabyOtter.sol";

contract BabyOtterTest is Test {
    BabyOtter internal _otter;

    function setUp() public {
        _otter = new BabyOtter();
    }

    function test_solve() public {
        // 0x1337
        uint256 multiplier = 4919;
        uint256 max = type(uint256).max;
        uint256 unit = max / multiplier;
        uint256 x;
        uint256 y;

        uint256 i;
        while (i < multiplier) {
            i++;

            x = max - (unit * i);

            unchecked {
                x += (max - (x * multiplier) - 1) / multiplier + 1;
                y = x * multiplier;
            }

            if (y == 1) {
                break;
            }
        }

        _otter.solve(x);

        assertTrue(_otter.solved(), "solved");
    }
}
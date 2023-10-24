// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./ConfidentialHash.sol";

contract ConfidentialHashTest is Test {
    Confidential internal _confidential;

    function setUp() public {
        _confidential = new Confidential();
    }

    function test_attack() public {
        bytes32 hash = _confidential.hash(
            vm.load(address(_confidential), bytes32(uint256(4))),
            vm.load(address(_confidential), bytes32(uint256(9)))
        );

        assertTrue(_confidential.checkthehash(hash));
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Setup.sol";

/// @notice The original solidity version of the challenge is 0.7.6,
///         Changes it to 0.8 for testing,
///         and to prevent errors when decoding from bytes to bytes4,
///         the v1 ABI coder is utilized for `SignatureChecker`.
contract VanityTest is Test {
    Setup internal _setup;

    function setUp() public {
        _setup = new Setup();
    }

    function test_attack() public {
        Challenge challenge = _setup.challenge();

        // https://www.evm.codes/precompiled
        // 0x02                   : SHA256
        //
        // selector               : 1626ba7e
        // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
        //
        // hash                   : 19bb34e293bba96bf0caeea54cdd3d2dad7fdf44cbea855173fa84534fcfb528
        // keccak256(abi.encodePacked("CHALLENGE_MAGIC"))
        //
        // input                  :
        // abi.encodeWithSelector(0x1626ba7e, 0x19bb34e293bba96bf0caeea54cdd3d2dad7fdf44cbea855173fa84534fcfb528, signature)
        //
        // requirement            :
        // sha256(input) has prefix 0x1626ba7e
        //
        // Available signatures :
        // 0x8cf1a8bb
        // 0x90975fe9
        // 0x90a349fe
        // 0x3333333333333333333333333333333333333333333333333333333361a733f6
        // 0x5555555555555555555555555555555555555555555555555555555568b60f5b
        challenge.solve(address(2), hex"3333333333333333333333333333333333333333333333333333333361a733f6");
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./GuessGame.sol";

/// https://github.com/MetaTrustLabs/ctf/blob/master/guessgame/contracts/A.sol
contract GuessGameTest is Test {
    SetUp internal _setup;

    function setUp() public {
        _setup = new SetUp();
    }

    receive() external payable {}

    /// @notice When a contract contains immutable variables,
    ///         the compiled bytecode will reserve space for them (32 bytes zero per variable).
    ///         After executing the constructor,
    ///         the values from memory will be loaded to the stack.
    ///         Then, the deployed bytecode will be copied to memory via codecopy,
    ///         and using mstore, the zero values in memory will be replaced with the values from the stack.
    function test_attackGame() public {
        // assembly {
        //     mstore(0x80, 1)
        //     mstore(0xa0, 2)
        //     mstore(0xc0, 32)
        // }
        //
        uint256 random01 = 1;
        uint256 random02 = 2;
        uint256 random03 = 32;

        address caller = address(this);

        // 1:
        // uint256[] memory arr;
        // mstore(_random01, money)
        // random01 == arr.length == 1
        //
        // The zero slot is used as initial value for dynamic memory arrays and should never be written to.
        uint256 a = 0x60;

        // 2:
        // uint256 y = (uint160(address(msg.sender)) + random01 + random02 + random03 + _random02) & 0xff;
        // require(random02 == y, "wrong number02");
        uint256 b = (uint160(caller) + random01 + random02 + random03) & 0xff;
        if (b > random02) {
            b = ((0xff + 1) - b) + random02;
        } else {
            b = random02 - b;
        }

        // 3:
        // require(uint160(_random03) < uint160(0x0000000000fFff8545DcFcb03fCB875F56bedDc4));
        // (,bytes memory data) = address(uint160(_random03)).staticcall("Fallbacker()");
        // require(random03 == data.length, "wrong number03");
        //
        // https://www.evm.codes/precompiled
        // https://www.rareskills.io/post/solidity-precompiles
        uint256 c = uint256(uint160(0x02));

        // 4:
        uint256 d = _setup.a().number();

        _setup.guessGame().guess{value: random01}(a, b, c, d);
    }
}

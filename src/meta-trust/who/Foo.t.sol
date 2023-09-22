// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Foo.sol";

contract Attacker {
    Foo internal _foo;

    uint256[] internal _result3;

    constructor(Foo foo_) {
        _foo = foo_;
    }

    function check() external view returns (bytes32) {
        uint256 gas = gasleft();

        // Address access gas cost
        // cold (first time) : 2600
        // warm              : 100
        uint256 b = address(0).balance;

        uint256 gasUsed = gas - gasleft();

        if (gasUsed >= 2000) {
            return keccak256(abi.encodePacked("1337"));
        } else {
            return keccak256(abi.encodePacked("13337"));
        }
    }

    function setup() external {
        _foo.setup();
    }

    function stage1() external {
        _foo.stage1();
    }

    function stage2() external {
        _foo.stage2();
    }

    function sort(uint256[] memory challenge) external view returns (uint256[] memory) {
        return _result3;
    }

    function setResult3() public {
        uint256[] memory challenge = new uint256[](8);

        challenge[0] = (block.timestamp & 0xf0000000) >> 28;
        challenge[1] = (block.timestamp & 0xf000000) >> 24;
        challenge[2] = (block.timestamp & 0xf00000) >> 20;
        challenge[3] = (block.timestamp & 0xf0000) >> 16;
        challenge[4] = (block.timestamp & 0xf000) >> 12;
        challenge[5] = (block.timestamp & 0xf00) >> 8;
        challenge[6] = (block.timestamp & 0xf0) >> 4;
        challenge[7] = (block.timestamp & 0xf) >> 0;

        for (uint i = 0; i < 8; i++) {
            for (uint j = i + 1; j < 8; j++) {
                if (challenge[i] > challenge[j]) {
                    uint tmp = challenge[i];
                    challenge[i] = challenge[j];
                    challenge[j] = tmp;
                }
            }
        }

        _result3 = challenge;
    }

    function stage3() external {
        // Sorts and stores values to storage in the same transaction.
        // when sort has been called, due to warm access, sload 8 slots = 800 gas
        setResult3();

        // Another complex solution: Sorter.sol
        // gas ≈ 1900

        _foo.stage3();
    }

    function stage4() external {
        _foo.stage4();
    }

    function pos() external view returns (bytes32) {
        // stats slot  : 1
        // stage       : 4
        // who         : address(this)
        return keccak256(abi.encode(address(this), keccak256(abi.encode(4, 1))));
    }
}

contract Factory {
    function deployAttacker(address foo, bytes32 salt) external returns (address) {
        return _deployContract(
            abi.encodePacked(type(Attacker).creationCode, abi.encode(foo)),
            salt);
    }

    function predictAddress(address foo, bytes32 salt) external view returns (address addr) {
        addr = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(type(Attacker).creationCode, abi.encode(foo)))
        )))));
    }

    function _deployContract(bytes memory code, bytes32 salt) internal returns (address addr) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
        }
    }
}

contract FooTest is Test {
    Foo internal _foo;
    Factory internal _factory;
    Attacker internal _attacker;

    function setUp() public {
        _foo = new Foo();
        _factory = new Factory();
        _attacker = _deployAttacker();

        vm.warp(1695111755);
    }

    function test_attack() public {
        _attacker.stage1();

        // Brute force gas
        _attacker.stage2{gas: 42000}();

        _attacker.stage3();

        _attacker.stage4();
    }

    function _deployAttacker() internal returns (Attacker) {
        for (uint256 i; i < 20000; i++) {
            address addr = _factory.predictAddress(address(_foo), bytes32(i));

            if (uint160(addr) % 1000 == 137) {
                Attacker attacker = Attacker(_factory.deployAttacker(address(_foo), bytes32(i)));
                attacker.setup();
                return attacker;
            }
        }

        revert("no valid address");
    }
}

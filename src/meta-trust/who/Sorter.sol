// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// Workaround solution for stage 3 (forgot sload warm access only cost 100):
/// Calculates the result and create a contract by bytecodes with fallback and returning fixed result,
/// then attacker call this function in the same transaction.
contract SorterTemplate {
    fallback(bytes calldata) external returns (bytes memory) {
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 320))

            mstore(add(ptr, 0), 0x0000000000000000000000000000000000000000000000000000000000000020)
            mstore(add(ptr, 32), 0x0000000000000000000000000000000000000000000000000000000000000008)
            mstore(add(ptr, 64), 0x0000000000000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 96), 0x0000000000000000000000000000000000000000000000000000000000000005)
            mstore(add(ptr, 128), 0x0000000000000000000000000000000000000000000000000000000000000005)
            mstore(add(ptr, 160), 0x0000000000000000000000000000000000000000000000000000000000000006)
            mstore(add(ptr, 192), 0x0000000000000000000000000000000000000000000000000000000000000007)
            mstore(add(ptr, 224), 0x0000000000000000000000000000000000000000000000000000000000000009)
            mstore(add(ptr, 256), 0x000000000000000000000000000000000000000000000000000000000000000a)
            mstore(add(ptr, 288), 0x000000000000000000000000000000000000000000000000000000000000000c)

            return (ptr, 320)
        }
    }
}

contract Sorter {
    fallback(bytes calldata) external returns (bytes memory) {
        // Pick template bytecode from SorterTemplate assembly block
        // mload and mstore new free pointer:
        // 604051610140808201604052
        // mstore offset:
        // 6020825260
        // mstore length:
        // 08602083015260
        // mstore values:
        // 00604083015260
        // 05606083015260
        // 05608083015260
        // 0660a083015260
        // 0760c083015260
        // 0960e083015260
        // 0a61010083015260
        // 0c610120830152
        // return:
        // 8082f3
        //
        bytes memory code = hex"6040516101408082016040526020825260086020830152600060408301526005606083015260056080830152600660a0830152600760c0830152600960e0830152600a610100830152600c6101208301528082f3";
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

        // Replaces values to sorted
        code[24] = bytes1(uint8(challenge[0]));
        code[31] = bytes1(uint8(challenge[1]));
        code[38] = bytes1(uint8(challenge[2]));
        code[45] = bytes1(uint8(challenge[3]));
        code[52] = bytes1(uint8(challenge[4]));
        code[59] = bytes1(uint8(challenge[5]));
        code[66] = bytes1(uint8(challenge[6]));
        code[74] = bytes1(uint8(challenge[7]));

        return code;

        // assembly version
        // start index: 24, offset: 32
//        assembly {
//            mstore8(add(code, 56), mload(add(challenge, 32)))
//            mstore8(add(code, 63), mload(add(challenge, 64)))
//            mstore8(add(code, 70), mload(add(challenge, 96)))
//            mstore8(add(code, 77), mload(add(challenge, 128)))
//            mstore8(add(code, 84), mload(add(challenge, 160)))
//            mstore8(add(code, 91), mload(add(challenge, 192)))
//            mstore8(add(code, 98), mload(add(challenge, 224)))
//            mstore8(add(code, 106), mload(add(challenge, 256)))
//
//            return (add(code, 32), mload(code))
//        }
    }
}
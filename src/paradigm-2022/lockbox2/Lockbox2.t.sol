// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import "./Setup.sol";

contract Lockbox2Test is Test {
    Setup internal _setup;

    function setUp() public {
        _setup = new Setup();
    }

    function test_attack() public {
        Lockbox2 lockbox = _setup.lockbox2();

        uint256 a = 97;
        uint256 b = 257;
        uint256 c = 1;
        uint256 d = 1;

        // stage 1:
        // msg.data.length < 500

        // stage 2:
        // a, b, c, d
        // number == 1 || (number > 1 && number is prime)

        // stage 3:
        // a, b, c
        //
        // When the code length of account is zero, call will always succeed,
        // and the length of result bytes points to memory 0x60 (zero slot).
        //
        // address(a + b).code.length == 0
        // After mstore(a, b), mload(0x60) == c
        // b >> 8 * (a - 96) == c

        // stage 4:
        // a, b, d
        // a: The offset of first bytes parameter
        // b: The offset of second bytes parameter
        //
        // a = 97, msg.data.length < 500
        // The length of first parameter will be msg.data[4:][97:127],
        // it means the last 31 bytes of d, then concat 0x00.
        // d must be 1,
        // and the length of first parameter will be 256 (0x100).
        //
        // tx.origin == address(uint160(uint256(addr.codehash))
        // wallet address = last 20 bytes from keccak256(publicKeyX, publicKeyY)
        // address(uint160(uint256(keccak256(abi.encode(wallet.publicKeyX, wallet.publicKeyY)))))

        // stage 5:
        // When it's first time calling `stage5`,
        // msg.sender != address(this),
        // it will call `solve` again, and this second `solve` must result in failure.

        // The first `solve` must be successful,
        // `creationCode` must return bytes.concat(publicKeyX, publicKeyY),
        // and this runtime code must be executable.
        //
        // publicKeyX starts with 0x00,
        // 00: STOP

        // Finds the account by `./find-account/main.go`
        // address
        // 0x2798ba84D7830c5F60D750f37f87D93277106905
        // publicKeyX
        // 0x00e3ae1974566ca06cc516d47e0fb165a674a3dabcfca15e722f0e3450f45889
        // publicKeyY
        // 0x2aeabe7e4531510116217f07bf4d07300de97e4874f81f533420a72eeb0bd6a4
        uint256 privateKey = uint256(0x0000000000000000000000000000000000000000000000000000000000000099);
        address playerAddress = vm.addr(privateKey);
        Vm.Wallet memory wallet = vm.createWallet(privateKey);

        // Generates the code by `PublicKey.huff`
        bytes memory creationCode = bytes.concat(
            // 1.
            // Calculates gas cost by accessing the balance of any unused address
            //
            // GAS
            // PUSH20 0xffffffffffffffffffffffffffffffffffffffff
            // BALANCE
            // POP
            // GAS
            // SWAP1
            // SUB
            hex"5a_73_ffffffffffffffffffffffffffffffffffffffff_31_50_5a_90_03",
            // 2.
            // If gas cost > 2000 (address cold access is 2600), jump to point 4
            //
            // PUSH2 0x07d0
            // SWAP1
            // GT
            // PUSH2 0x002e
            // JUMPI
            hex"61_07d0_90_11_61_002e_57",
            // 3.
            // When gas cost <= 2000 (warm access),
            // return the invalid result
            // 0x0000000000000000000000000000000000000000000000000000000000000000
            //
            // PUSH1 0x00
            // PUSH1 0x00
            // MSTORE
            // PUSH1 0x20
            // PUSH1 0x00
            // RETURN
            hex"60_00_60_00_52_60_20_60_00_f3",
            // 4.
            // Puts publicKeyX to memory [0:32] and publicKeyY to [32:64],
            // then return memory[0:64]
            //
            // JUMPDEST
            // PUSH32 publicKeyX
            // PUSH1 0x00
            // MSTORE
            // PUSH32 publicKeyY
            // PUSH1 0x20
            // MSTORE
            // PUSH1 0x40
            // PUSH1 0x00
            // RETURN
            hex"5b_7f",
            bytes32(wallet.publicKeyX),
            hex"60_00_52_7f",
            bytes32(wallet.publicKeyY),
            hex"60_20_52_60_40_60_00_f3"
        );

        bytes memory prefix = new bytes(a - 96);
        // Fills the data to 499 bytes
        bytes memory suffix = new bytes(500 - 1 - (4 + 128 + prefix.length + creationCode.length));

        bytes memory data = bytes.concat(
            hex"890d6908",
            bytes32(a),
            bytes32(b),
            bytes32(c),
            bytes32(d),
            prefix,
            creationCode,
            suffix
        );

        vm.startPrank(playerAddress, playerAddress);

        (bool ok,) = address(lockbox).call(data);

        vm.stopPrank();

        assertTrue(_setup.isSolved());
    }
}
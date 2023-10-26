// Finds the account that the public key x starts with 0x00
package main

import (
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/holiman/uint256"
	"log"
	"time"
)

func main() {
    prefix := byte(0x00)
    one := uint256.MustFromDecimal("1")
	privateKeyValue := uint256.MustFromDecimal("1")
	startTime := time.Now()

	for {
		privateKeyBytes := common.LeftPadBytes(privateKeyValue.Bytes(), 32)

		privateKey, err := crypto.HexToECDSA(common.Bytes2Hex(privateKeyBytes))
		if err != nil {
			log.Panicln(err)
		}

		publicKeyXBytes := common.LeftPadBytes(privateKey.PublicKey.X.Bytes(), 32)

		if publicKeyXBytes[0] == prefix {
			publicKeyYBytes := common.LeftPadBytes(privateKey.PublicKey.Y.Bytes(), 32)
			log.Println("address", crypto.PubkeyToAddress(privateKey.PublicKey).String())
			log.Println("private key", common.Bytes2Hex(privateKeyBytes))
			log.Println("public key x", common.Bytes2Hex(publicKeyXBytes))
			log.Println("public key y", common.Bytes2Hex(publicKeyYBytes))
			log.Println("duration", time.Now().Sub(startTime))
			break
		}

		privateKeyValue = privateKeyValue.Add(privateKeyValue, one)
	}
}

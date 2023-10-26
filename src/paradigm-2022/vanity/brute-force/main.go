// Brute force guessing the signature parameter,
// with support for resuming execution.
//
// cmd:
// go run main.go
//
// cfg:
// goroutineCount | duration
// 1              | 46m
// 5              | 25m
// 12             | 1h8m
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/holiman/uint256"
	"log"
	"os"
	"os/signal"
	"runtime"
	"strings"
	"sync"
	"time"
)

const (
	selector       = "1626ba7e"                                                         // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
	magic          = "19bb34e293bba96bf0caeea54cdd3d2dad7fdf44cbea855173fa84534fcfb528" // keccak256(abi.encodePacked("CHALLENGE_MAGIC"))
	StatusFileName = "status.json"
)

var (
	goroutineCount = runtime.NumCPU()
	minValue       = uint256.MustFromDecimal("0")
	maxValue       = uint256.MustFromDecimal("115792089237316195423570985008687907853269984665640564039457584007913129639935")
	magicBytes     []byte
	magicBytes32   [32]byte
	bytesType      abi.Type
	bytes32Type    abi.Type
	args           abi.Arguments
)

type ValueRange struct {
	Min     *uint256.Int `json:"min"`
	Max     *uint256.Int `json:"max"`
	Current *uint256.Int `json:"current"`
}

type Status struct {
	Duration   int64             `json:"duration"`
	Ranges     []*ValueRange     `json:"ranges"`
	MatchedMap map[string]string `json:"matched_map"`
}

func init() {
	magicBytes, _ = hex.DecodeString(magic)
	copy(magicBytes32[:], magicBytes[0:32])

	bytesType, _ := abi.NewType("bytes", "", nil)
	bytes32Type, _ := abi.NewType("bytes32", "", nil)

	args = abi.Arguments{
		{Type: bytes32Type, Name: "hash"},
		{Type: bytesType, Name: "signature"},
	}
}

func BytesToSHA256Hex(b []byte) string {
	sum := sha256.Sum256(b)

	return fmt.Sprintf("%x", sum)
}

func encodeThenSHA256(sigValue *uint256.Int) (string, error) {
	ret, err := args.Pack(magicBytes32, sigValue.Bytes())
	if err != nil {
		return "", err
	}

	payloadB, _ := hex.DecodeString(selector)
	payloadB = append(payloadB, ret...)

	return BytesToSHA256Hex(payloadB), nil
}

func SyncMapToMap(m *sync.Map) (ret map[string]string) {
	ret = map[string]string{}

	m.Range(func(key, value any) bool {
		ret[key.(string)] = value.(string)
		return true
	})

	return
}

func MapToSyncMap(m map[string]string) (ret *sync.Map) {
	ret = &sync.Map{}

	for key, value := range m {
		ret.Store(key, value)
	}

	return
}

func loadStatus() (*Status, error) {
	b, err := os.ReadFile(StatusFileName)

	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}

	status := &Status{}

	if err == nil {
		err = json.Unmarshal(b, status)
		return status, err
	}

	// Init ranges
	for i, length := 0, goroutineCount; i < length; i++ {
		totalCount := maxValue.Clone()
		totalCount.Sub(totalCount, minValue)

		unit := uint256.NewInt(0).Div(totalCount, uint256.NewInt(uint64(length)))

		begin := uint256.NewInt(0).Mul(unit, uint256.NewInt(uint64(i)))
		begin.Add(begin, minValue)

		end := uint256.NewInt(0)
		if i == length-1 {
			end = maxValue.Clone()
		} else {
			end = end.Add(begin, unit)
			end = end.Sub(end, uint256.NewInt(1))
		}

		status.Ranges = append(status.Ranges, &ValueRange{
			Min:     begin.Clone(),
			Max:     end,
			Current: begin.Clone(),
		})
	}

	return status, nil
}

func saveStatus(status *Status) error {
	outputB, err := json.MarshalIndent(status, "", "\t")
	if err != nil {
		return err
	}

	return os.WriteFile(StatusFileName, outputB, 0644)
}

func printStatus(status *Status, duration time.Duration) {
	totalProcessed := uint256.MustFromDecimal("0")
	totalRemaining := uint256.MustFromDecimal("0")
	for _, item := range status.Ranges {
		processed := item.Current.Clone()
		remaining := item.Max.Clone()

		processed.Sub(processed, item.Min)
		remaining.Sub(remaining, item.Current)

		totalProcessed.Add(totalProcessed, processed)
		totalRemaining.Add(totalRemaining, remaining)
	}

	log.Println("duration", duration)
	log.Println("total duration", time.Duration(status.Duration))
	log.Println("total processed count", totalProcessed.Dec())
	log.Println("total remaining count", totalRemaining.Dec())
}

func main() {
	status, err := loadStatus()
	if err != nil {
		log.Panicln("status load failed", err)
	}

	matchedMap := MapToSyncMap(status.MatchedMap)
	one := uint256.NewInt(1)
	startTime := time.Now()
	beginDuration := status.Duration

	for i, valueRange := range status.Ranges {
		go func(i int, valueRange *ValueRange) {
			current := valueRange.Current
			max := valueRange.Max

			log.Printf(
				"range id: %04d, current: 0x%x, max: 0x%x",
				i,
				current.Bytes32(),
				max.Bytes32())

			for current.Cmp(max) < 1 {
				hash, err := encodeThenSHA256(current)

				if err == nil && strings.HasPrefix(hash, selector) {
					log.Println("matched signature", current.String())
					log.Println("matched hash", hash)
					log.Println("matched duration",
						time.Duration(beginDuration+time.Now().Sub(startTime).Nanoseconds()),
					)

					matchedMap.Store(current.String(), hash)
				}
				current.Add(current, one)
			}
		}(i, valueRange)
	}

	signals := make(chan os.Signal, 1)
	signal.Notify(signals, os.Interrupt)

	<-signals

	duration := time.Now().Sub(startTime)
	status.Duration += duration.Nanoseconds()
	status.MatchedMap = SyncMapToMap(matchedMap)

	if err := saveStatus(status); err != nil {
		log.Panicln("status save failed", err)
	}

	printStatus(status, duration)
}

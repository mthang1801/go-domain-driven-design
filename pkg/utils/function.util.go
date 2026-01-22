package utils

import (
	"math/rand"
	"time"
)

// RandomNumber generates a random number between min and max with decimal places (default)
func RandomNumber(min, max float64) float64 {
	return randomNumberWithOptions(min, max, true)
}

// RandomNumberInt generates a random integer between min and max
func RandomNumberInt(min, max float64) float64 {
	return randomNumberWithOptions(min, max, false)
}

// RandomNumberWithDecimal generates a random number between min and max
// If useDecimal is true, returns a float64 with decimal places
// If useDecimal is false, returns a float64 but as an integer value
func RandomNumberWithDecimal(min, max float64, useDecimal bool) float64 {
	return randomNumberWithOptions(min, max, useDecimal)
}

// randomNumberWithOptions is the internal implementation
func randomNumberWithOptions(min, max float64, useDecimal bool) float64 {
	// Seed the random number generator
	rand.Seed(time.Now().UnixNano())

	if min >= max {
		return min
	}

	if useDecimal {
		// Generate random float with decimal places
		return min + rand.Float64()*(max-min)
	} else {
		// Generate random integer
		rangeSize := int(max - min + 1)
		randomInt := rand.Intn(rangeSize)
		return min + float64(randomInt)
	}
}

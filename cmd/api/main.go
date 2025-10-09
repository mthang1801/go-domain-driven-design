package main

import "fmt"

func divide(a, b float64) (float64, error) {
	if b == 0 {
		return 0, fmt.Errorf("Cannot devide by zero")
	}

	return a / b, nil
}

func calculate(a, b int) (sum int, product int) {
	sum = a + b
	product = a * b
	return
}


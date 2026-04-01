package main

import (
	"fmt"
	"go-domain-driven-design/pkg/utils"
	"time"
)

func deferArgsTrap() {
	x := 10
	defer fmt.Println("defer with arg:", x)
	x = 20
	fmt.Println("current x:", x) // 20
}

func readFileWithRetry(path string) (data []byte, err error) {
	defer func() {
		if err != nil {
			err = fmt.Errorf("readFileWithRetry(%s): %w", path, err)
		}
	}()
	return nil, fmt.Errorf("file not found")
}

func measureTime(name string) func() {
	start := time.Now()
	return func() {
		fmt.Printf("⏱ %s took %v\n", name, time.Since(start))
	}
}

func expensiveOperation() {
	defer measureTime("expensiveOperation")()
}

func main() {
	defer measureTime("handleFile")()
	data, res := readFileWithRetry("nonexistent.txt")
	time.Sleep(time.Duration(utils.RandomNumber(100, 2000)) * time.Millisecond)
	fmt.Println(data, res)
}

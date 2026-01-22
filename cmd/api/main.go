package main

import (
	"fmt"
	"time"
)

func orDone(done <-chan struct{}, in <-chan int) chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for {
			select {
			case <-done:
				return
			case v, ok := <-in:
				if !ok {
					return
				}
				out <- v
			}
		}
	}()
	return out
}

func main() {
	done := make(chan struct{})
	in := make(chan int)

	go func() {
		for i := 0; i < 5; i++ {
			in <- i
			time.Sleep(500 * time.Millisecond)
		}
		close(in)
	}()

	go func() {
		time.Sleep(time.Second * 2)
		done <- struct{}{}
	}()

	for v := range orDone(done, in) {
		fmt.Println(v)
	}
}

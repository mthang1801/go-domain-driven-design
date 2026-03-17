package main

import (
	"context"
	"go-domain-driven-design/pkg/utils"
	"sync"
	"time"

	"github.com/Jeffail/tunny"
	"golang.org/x/sync/errgroup"
)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*5)
	defer cancel()

	bufferPool := sync.Pool{
		New: func() interface{} { return make([]byte, 1024) },
	}

	tunny := tunny.NewFunc(4, func(payload interface{}) interface{} {
		num := payload.(int)
		buf := bufferPool.Get().([]byte)
		defer bufferPool.Put(buf)
		time.Sleep(time.Duration(utils.RandomNumber(100, 2000)) * time.Millisecond)
		return num * num
	})

	defer tunny.Close()

	input := make(chan int, 10)
	output := make(chan int, 10)

	go func() {
		defer close(input)
		for i := 0; i < 50; i++ {
			select {
			case <-ctx.Done():
				return
			case input <- i:
			}
		}
	}()

	eg, ctx := errgroup.WithContext(ctx)

	// Goroutine 1: xử lý từng số và gửi kết quả vào output
	eg.Go(func() error {
		defer close(output) // đóng output khi input đã hết
		for num := range input {
			result := tunny.Process(num)
			select {
			case <-ctx.Done():
				return ctx.Err()
			case output <- result.(int):
			}
		}
		return nil
	})

	// Goroutine 2: đọc kết quả từ output channel
	eg.Go(func() error {
		for v := range output {
			// Xử lý kết quả ở đây
			println("Result:", v)
		}
		return nil
	})

	if err := eg.Wait(); err != nil {
		println("Error:", err.Error())
	}
}

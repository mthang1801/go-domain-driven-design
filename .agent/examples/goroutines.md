Advanced Example: Tee in a worker pool manager with Tunny, fan-in/fan-out, and error groups. This models a logging system where events are teed to a processor and a logger, with dynamic workers.

```
package main

import (
	"context"
	"fmt"
	"go-domain-driven-design/pkg/utils"
	"runtime"
	"sync"
	"time"

	"github.com/Jeffail/tunny"
	"golang.org/x/sync/errgroup"
)

func teeContext(ctx context.Context, in <-chan string) (<-chan string, <-chan string) {
	out1 := make(chan string, 10)
	out2 := make(chan string, 10)
	go func() {
		defer close(out1)
		defer close(out2)
		for {
			select {
			case <-ctx.Done():
				return
			case v, ok := <-in:
				if !ok {
					return
				}
				ch1, ch2 := out1, out2
				for i := 0; i < 2; i++ {
					select {
					case ch1 <- v:
						ch1 = nil
					case ch2 <- v:
						ch2 = nil
					case <-ctx.Done():
						return
					}
				}
			}
		}
	}()
	return out1, out2
}

func processor(id int, in <-chan string, out chan<- string) error {
	for v := range in {
		time.Sleep(time.Duration(utils.RandomNumberInt(100, 1000)) * time.Millisecond)
		out <- fmt.Sprintf("Processed by %d: %s", id, v)
	}
	return nil
}

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*5)
	defer cancel()

	events := make(chan string, 10)

	go func() {
		for i := 1; i <= 50; i++ {
			events <- fmt.Sprintf("Event %d", i)
		}
		close(events)
	}()

	procIn, logIn := teeContext(ctx, events)

	go func() {
		for v := range logIn {
			fmt.Println("Logged: ", v)
		}
	}()

	pool := tunny.NewFunc(runtime.NumCPU(), func(payload interface{}) interface{} {
		in := payload.(<-chan string)
		out := make(chan string, 10)
		var wg sync.WaitGroup
		for i := 1; i <= runtime.NumCPU(); i++ {
			wg.Add(1)
			go func(id int) {
				defer wg.Done()
				processor(id, in, out)
			}(i)
		}

		go func() {
			wg.Wait()
			close(out)
		}()
		return out
	})

	defer pool.Close()

	eg, ctx := errgroup.WithContext(ctx)
	eg.Go(func() error {
		result := pool.Process(procIn).(chan string)
		if result == nil {
			return fmt.Errorf("result is nil")
		}

		for v := range result {
			fmt.Println("Processed: ", v)
		}
		return nil
	})

	go func() {
		for {
			qLen := pool.QueueLength()
			fmt.Println("================= Queue Length: ==================== ", qLen)
			if qLen == 0 {
				break
			}
			time.Sleep(time.Second)
		}
	}()

	if err := eg.Wait(); err != nil {
		fmt.Println("Error: ", err)
	}
	fmt.Println("Done")

}
```
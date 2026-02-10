```package main

import (
	"context"
	"fmt"
	"go-domain-driven-design/pkg/utils"
	"log"
	"math/rand"
	"runtime"
	"sync"
	"time"

	"github.com/Jeffail/tunny"
	"golang.org/x/sync/errgroup"
)

type Transaction struct {
	ID         string
	Amount     float64
	Currency   string
	Merchant   string
	Timestamp  time.Time
	CustomerID string
}

func orDoneCtx[T any](ctx context.Context, in <-chan T) <-chan T {
	out := make(chan T)
	go func() {
		defer close(out)
		for {
			select {
			case <-ctx.Done():
				return
			case v, ok := <-in:
				if !ok {
					return
				}
				select {
				case <-ctx.Done():
					return
				case out <- v:
				}
			}
		}
	}()
	return out
}

func teeCtx[T any](ctx context.Context, in <-chan T) (<-chan T, <-chan T) {
	out1 := make(chan T)
	out2 := make(chan T)
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
				for ch1, ch2 := out1, out2; ch1 != nil && ch2 != nil; {
					select {
					case <-ctx.Done():
						return
					case ch1 <- v:
						ch1 = nil
					case ch2 <- v:
						ch2 = nil
					}
				}
			}
		}
	}()
	return out1, out2
}

func fraudDetector(ctx context.Context, in <-chan Transaction) {
	for transaction := range orDoneCtx(ctx, in) {
		if transaction.Amount > 700 {
			log.Printf("[FRAUD] Hight amount alert | TxID: %s | Amount: %s%.2f | Merchant: %s\n", transaction.ID, transaction.Currency, transaction.Amount, transaction.Merchant)
		} else if rand.Float32() < 0.05 {
			log.Printf("[FRAUD] Suspicious Pattern | TxID: %s | Amount: %s%.2f | Merchant: %s\n", transaction.ID, transaction.Currency, transaction.Amount, transaction.Merchant)
		} else {
			log.Printf("[FRAUD] Normal: %s %s%.2f\n", transaction.ID, transaction.Currency, transaction.Amount)
		}
	}

	log.Println("[FRAUD] Detector shutdown")
}

type AnalyticsWorker struct {
	mu           sync.Mutex
	total        int
	successCount int
}

func NewAnalyticsWorker() *AnalyticsWorker {
	return &AnalyticsWorker{}
}

func (w *AnalyticsWorker) Process(transaction interface{}) interface{} {
	w.mu.Lock()
	w.total++
	if transaction.(Transaction).Amount <= 700 {
		w.successCount++
	}
	time.Sleep(time.Duration(utils.RandomNumber(10, 1000)) * time.Millisecond)

	w.mu.Unlock()
	return nil
}

func (w *AnalyticsWorker) GetSummary() {
	w.mu.Lock()
	defer w.mu.Unlock()

	if w.successCount > 0 {
		avg := float64(w.total) / float64(w.successCount) / 100
		fmt.Printf("[ANALYTICS] Summary | Transactions: %d | Total: $%.2f | Avg: $%.2f\n",
			w.successCount, float64(w.total)/100, avg)
	}
}


func analyticsPipeline(ctx context.Context, in <-chan Transaction, pool *tunny.Pool, worker *AnalyticsWorker) {
	var wg sync.WaitGroup
	for transaction := range in {
		wg.Add(1)
		go func() {
			defer wg.Done()
			pool.Process(transaction)
		}()
	}
	wg.Wait()
	worker.GetSummary()
}

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*10)
	defer cancel()

	eg, ctx := errgroup.WithContext(ctx)

	transactionGenerator := make(chan Transaction, 100)

	eg.Go(func() error {
		defer close(transactionGenerator)
		for i := 0; i < 200; i++ {
			select {
			case <-ctx.Done():
				return ctx.Err()
			default:

				transaction := Transaction{
					ID:         fmt.Sprintf("%d", i),
					Amount:     float64(utils.RandomNumber(100, 2000)),
					Currency:   "$",
					Merchant:   "Merchant" + fmt.Sprintf("%d", utils.RandomNumberInt(1, 10)),
					Timestamp:  time.Now(),
					CustomerID: "Customer" + fmt.Sprintf("%d", utils.RandomNumberInt(1, 100)),
				}
				transactionGenerator <- transaction
				time.Sleep(time.Duration(utils.RandomNumber(10, 80)+30) * time.Millisecond)
			}
		}
		fmt.Println("[PRODUCER] All transactions sent")
		return nil
	})

	fraudCh, analyticsCh := teeCtx(ctx, transactionGenerator)

	eg.Go(func() error {
		fraudDetector(ctx, fraudCh)
		return nil
	})

	analyticsWorker := NewAnalyticsWorker()
	pool := tunny.NewFunc(runtime.NumCPU(), analyticsWorker.Process)
	defer pool.Close()

	eg.Go(func() error {
		analyticsPipeline(ctx, analyticsCh, pool, analyticsWorker)
		return nil
	})

	// Chờ tất cả hoàn thành hoặc timeout
	if err := eg.Wait(); err != nil {
		fmt.Printf("[MAIN] Finished with error: %v\n", err)
	} else {
		fmt.Println("[MAIN] All pipelines completed successfully")
	}

	fmt.Println("Done:", ctx.Err())
}
```
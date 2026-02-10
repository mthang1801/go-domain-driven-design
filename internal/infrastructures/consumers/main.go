package main

import (
	"go-domain-driven-design/internal/infrastructures/tasks"
	"log"

	"github.com/hibiken/asynq"
)

func main() {
	srv := asynq.NewServer(asynq.RedisClientOpt{Addr: "localhost:6379"}, asynq.Config{
		Concurrency: 10,
		Queues: map[string]int{
			"default":  3,
			"critical": 6,
			"low":      1,
		},
	})

	mux := asynq.NewServeMux()

	mux.HandleFunc(tasks.TypeEmail, tasks.HandleEmailTask)
	if err := srv.Run(mux); err != nil {
		log.Fatalf("Could not run server: %v", err)
	}
}

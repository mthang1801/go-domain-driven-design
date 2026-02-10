package main

import (
	"go-domain-driven-design/internal/infrastructures/tasks"
	"log"

	"github.com/hibiken/asynq"
)

func main() {
	client := asynq.NewClient(asynq.RedisClientOpt{Addr: "localhost:6379"})
	defer client.Close()

	task, err := tasks.NewEmailTask("test@example.com", "Test Subject", "Test Body")

	if err != nil {
		log.Fatalf("Could not create task %v", err)
	}

	info, err := client.Enqueue(task)

	if err != nil {
		log.Fatalf("Could not enqueue task: %v", err)
	}

	log.Printf("Enqueued task: id=%s, queue=%s", info.ID, info.Queue)
}

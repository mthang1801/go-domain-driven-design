package tasks

import (
	"context"
	"encoding/json"
	"fmt"
	"go-domain-driven-design/pkg/utils"
	"log"
	"time"

	"github.com/hibiken/asynq"
)

type EmailPayload struct {
	Email   string
	Subject string
	Body    string
}

func NewEmailTask(email string, subject string, body string) (*asynq.Task, error) {
	payload, err := json.Marshal(EmailPayload{
		Email:   email,
		Subject: subject,
		Body:    body,
	})

	if err != nil {
		return nil, err
	}

	return asynq.NewTask(TypeEmail, payload), nil
}

func HandleEmailTask(ctx context.Context, t *asynq.Task) error {
	var p EmailPayload
	if err := json.Unmarshal(t.Payload(), &p); err != nil {
		return fmt.Errorf("json.Unmarshal failed: %v, %w", err, asynq.SkipRetry)
	}

	log.Printf("[PROCESSING][%s] Sending email to user: email=%s, subject=%s", t.ResultWriter().TaskID() , p.Email, p.Subject)
	time.Sleep(time.Duration(utils.RandomNumberInt(100, 2000)) * time.Millisecond)
	log.Printf("[PROCESSED] Email sent to user: email=%s, subject=%s", p.Email, p.Subject)

	return nil
}

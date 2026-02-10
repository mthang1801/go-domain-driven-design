package container

import (
	"context"
	"fmt"
	"time"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

// PostgresContainer represents a running PostgreSQL container
type PostgresContainer struct {
	Container  *postgres.PostgresContainer
	ConnString string
}

// StartPostgres starts a PostgreSQL 16 container
func StartPostgres(ctx context.Context) (*PostgresContainer, func(), error) {
	dbName := "testdb"
	dbUser := "testuser"
	dbPassword := "testpassword"

	pgContainer, err := postgres.Run(ctx,
		"postgres:16-alpine",
		postgres.WithDatabase(dbName),
		postgres.WithUsername(dbUser),
		postgres.WithPassword(dbPassword),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).
				WithStartupTimeout(5*time.Second)),
	)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to start postgres container: %w", err)
	}

	connStr, err := pgContainer.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		pgContainer.Terminate(ctx)
		return nil, nil, fmt.Errorf("failed to get connection string: %w", err)
	}

	cleanup := func() {
		if err := pgContainer.Terminate(ctx); err != nil {
			fmt.Printf("failed to terminate postgres container: %v\n", err)
		}
	}

	return &PostgresContainer{
		Container:  pgContainer,
		ConnString: connStr,
	}, cleanup, nil
}

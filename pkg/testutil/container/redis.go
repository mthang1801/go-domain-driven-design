package container

import (
	"context"
	"fmt"

	"github.com/testcontainers/testcontainers-go/modules/redis"
)

// RedisContainer represents a running Redis container
type RedisContainer struct {
	Container *redis.RedisContainer
	Addr      string
}

// StartRedis starts a Redis 7 container
func StartRedis(ctx context.Context) (*RedisContainer, func(), error) {
	redisContainer, err := redis.Run(ctx,
		"redis:7-alpine",
		redis.WithSnapshotting(10, 1),
		redis.WithLogLevel(redis.LogLevelVerbose),
	)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to start redis container: %w", err)
	}

	endpoint, err := redisContainer.ConnectionString(ctx)
	if err != nil {
		redisContainer.Terminate(ctx)
		return nil, nil, fmt.Errorf("failed to get redis endpoint: %w", err)
	}

	// ConnectionString returns "redis://host:port", we might need just "host:port" for some clients
	// But go-redis supports URL parsing, so keeping it as is for now.

	cleanup := func() {
		if err := redisContainer.Terminate(ctx); err != nil {
			fmt.Printf("failed to terminate redis container: %v\n", err)
		}
	}

	return &RedisContainer{
		Container: redisContainer,
		Addr:      endpoint,
	}, cleanup, nil
}

---
name: nestjs-configuration
description: NestJS configuration management best practices using ConfigService with type safety and validation.
---

# NestJS Configuration Management

Best practices for managing configuration in NestJS applications using ConfigService.

## Core Principles

1. **Never use `process.env` directly** - Always use ConfigService
2. **Validate early** - Fail fast on startup if config is invalid
3. **Type safety** - Use TypeScript interfaces for configuration
4. **Namespace configs** - Group related configuration
5. **Environment-specific** - Support dev, staging, prod

## Basic Setup

### 1. Install Dependencies

```bash
pnpm add @nestjs/config
pnpm add -D joi @types/joi  # For validation
```

### 2. Module Configuration

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { validationSchema } from './config/validation';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,              // Make available everywhere
      cache: true,                 // Cache values for performance
      expandVariables: true,       // Support variable expansion ${VAR}
      validationSchema,            // Joi validation schema
      validationOptions: {
        allowUnknown: true,        // Allow extra env vars
        abortEarly: false,         // Validate all fields
      },
      envFilePath: [
        `.env.${process.env.NODE_ENV}`,  // .env.production
        '.env',                           // Fallback
      ],
    }),
  ],
})
export class AppModule {}
```

## Validation Schema

### Environment Variable Validation

```typescript
// config/validation.ts
import * as Joi from 'joi';

export const validationSchema = Joi.object({
  // Application
  NODE_ENV: Joi.string()
    .valid('development', 'staging', 'production', 'test')
    .default('development'),
  PORT: Joi.number().port().default(3000),
  API_PREFIX: Joi.string().default('api'),

  // Database
  DATABASE_HOST: Joi.string().required(),
  DATABASE_PORT: Joi.number().port().default(5432),
  DATABASE_USER: Joi.string().required(),
  DATABASE_PASSWORD: Joi.string().required(),
  DATABASE_NAME: Joi.string().required(),
  DATABASE_SSL: Joi.boolean().default(false),

  // Redis
  REDIS_HOST: Joi.string().required(),
  REDIS_PORT: Joi.number().port().default(6379),
  REDIS_PASSWORD: Joi.string().allow('').optional(),
  REDIS_DB: Joi.number().default(0),

  // External APIs
  OPENAI_API_KEY: Joi.string().required(),
  STRIPE_SECRET_KEY: Joi.string().when('NODE_ENV', {
    is: 'production',
    then: Joi.required(),
    otherwise: Joi.optional(),
  }),

  // JWT
  JWT_SECRET: Joi.string().min(32).required(),
  JWT_EXPIRATION: Joi.string().default('1h'),

  // Logging
  LOG_LEVEL: Joi.string()
    .valid('error', 'warn', 'info', 'debug', 'verbose')
    .default('info'),
});
```

## Type-Safe Configuration

### Configuration Interfaces

```typescript
// config/interfaces/database.config.ts
export interface DatabaseConfig {
  host: string;
  port: number;
  username: string;
  password: string;
  database: string;
  ssl: boolean;
  pool: {
    min: number;
    max: number;
  };
}

// config/interfaces/app.config.ts
export interface AppConfig {
  port: number;
  environment: string;
  apiPrefix: string;
  corsOrigin: string[];
}

// config/interfaces/redis.config.ts
export interface RedisConfig {
  host: string;
  port: number;
  password?: string;
  db: number;
  ttl: number;
}
```

### Configuration Factories

```typescript
// config/database.config.ts
import { registerAs } from '@nestjs/config';
import { DatabaseConfig } from './interfaces/database.config';

export default registerAs('database', (): DatabaseConfig => ({
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT, 10) || 5432,
  username: process.env.DATABASE_USER || 'postgres',
  password: process.env.DATABASE_PASSWORD || 'postgres',
  database: process.env.DATABASE_NAME || 'mydb',
  ssl: process.env.DATABASE_SSL === 'true',
  pool: {
    min: parseInt(process.env.DATABASE_POOL_MIN, 10) || 2,
    max: parseInt(process.env.DATABASE_POOL_MAX, 10) || 10,
  },
}));

// config/app.config.ts
import { registerAs } from '@nestjs/config';
import { AppConfig } from './interfaces/app.config';

export default registerAs('app', (): AppConfig => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  environment: process.env.NODE_ENV || 'development',
  apiPrefix: process.env.API_PREFIX || 'api',
  corsOrigin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
}));

// config/redis.config.ts
import { registerAs } from '@nestjs/config';
import { RedisConfig } from './interfaces/redis.config';

export default registerAs('redis', (): RedisConfig => ({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT, 10) || 6379,
  password: process.env.REDIS_PASSWORD,
  db: parseInt(process.env.REDIS_DB, 10) || 0,
  ttl: parseInt(process.env.REDIS_TTL, 10) || 3600,
}));
```

### Register Configuration Files

```typescript
// app.module.ts
import { ConfigModule } from '@nestjs/config';
import databaseConfig from './config/database.config';
import appConfig from './config/app.config';
import redisConfig from './config/redis.config';
import { validationSchema } from './config/validation';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig, appConfig, redisConfig],
      validationSchema,
    }),
  ],
})
export class AppModule {}
```

## Usage Patterns

### In Services

```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseConfig } from './config/interfaces/database.config';

@Injectable()
export class DatabaseService {
  constructor(private readonly configService: ConfigService) {}

  // ✅ GOOD: Type-safe namespace access
  getConnection() {
    const dbConfig = this.configService.get<DatabaseConfig>('database');
    
    return {
      host: dbConfig.host,
      port: dbConfig.port,
      // ... TypeScript knows all properties
    };
  }

  // ✅ GOOD: Direct namespace property access
  getHost() {
    return this.configService.get<string>('database.host');
  }

  // ✅ GOOD: With getOrThrow (fails if missing)
  getApiKey() {
    return this.configService.getOrThrow<string>('OPENAI_API_KEY');
  }

  // ✅ GOOD: With default value
  getTimeout() {
    return this.configService.get<number>('API_TIMEOUT', 5000);
  }

  // ❌ BAD: Direct process.env access
  getBadExample() {
    return process.env.DATABASE_HOST; // Don't do this!
  }
}
```

### In Module Configuration

```typescript
// infrastructure/database/typeorm.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import { DatabaseConfig } from '@/config/interfaces/database.config';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const dbConfig = configService.get<DatabaseConfig>('database');
        
        return {
          type: 'postgres',
          host: dbConfig.host,
          port: dbConfig.port,
          username: dbConfig.username,
          password: dbConfig.password,
          database: dbConfig.database,
          ssl: dbConfig.ssl,
          entities: ['dist/**/*.orm-entity.js'],
          synchronize: false,
          logging: configService.get('NODE_ENV') === 'development',
          poolSize: dbConfig.pool.max,
        };
      },
    }),
  ],
})
export class DatabaseModule {}
```

### In Guards/Interceptors

```typescript
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class MaintenanceGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const maintenanceMode = this.configService.get<boolean>(
      'MAINTENANCE_MODE',
      false
    );

    return !maintenanceMode;
  }
}
```

## Environment Files

### File Structure

```
project-root/
├── .env                    # Default (gitignored)
├── .env.development        # Development (gitignored)
├── .env.staging            # Staging (gitignored)
├── .env.production         # Production (gitignored)
├── .env.test               # Test (committed)
└── .env.example            # Template (committed)
```

### .env.example (Template)

```bash
# Application
NODE_ENV=development
PORT=3000
API_PREFIX=api

# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=changeme
DATABASE_NAME=mydb
DATABASE_SSL=false
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
REDIS_TTL=3600

# External APIs
OPENAI_API_KEY=sk-proj-xxxxx
STRIPE_SECRET_KEY=sk_test_xxxxx

# JWT
JWT_SECRET=your-super-secret-key-min-32-chars
JWT_EXPIRATION=1h

# Logging
LOG_LEVEL=info

# CORS
CORS_ORIGIN=http://localhost:3000,http://localhost:3001
```

## Best Practices

### 1. Early Validation

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Get ConfigService
  const configService = app.get(ConfigService);
  
  // Verify critical configs on startup
  const requiredConfigs = [
    'DATABASE_HOST',
    'REDIS_HOST',
    'JWT_SECRET',
  ];
  
  requiredConfigs.forEach(key => {
    if (!configService.get(key)) {
      throw new Error(`Missing required config: ${key}`);
    }
  });
  
  const port = configService.get<number>('PORT', 3000);
  await app.listen(port);
}
bootstrap();
```

### 2. Configuration Service

Create a dedicated configuration service for complex logic:

```typescript
// shared/services/app-config.service.ts
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppConfig } from '@/config/interfaces/app.config';

@Injectable()
export class AppConfigService {
  constructor(private readonly configService: ConfigService) {}

  get app(): AppConfig {
    return this.configService.get<AppConfig>('app');
  }

  get isDevelopment(): boolean {
    return this.app.environment === 'development';
  }

  get isProduction(): boolean {
    return this.app.environment === 'production';
  }

  get isTest(): boolean {
    return this.app.environment === 'test';
  }

  get baseUrl(): string {
    return `http://localhost:${this.app.port}/${this.app.apiPrefix}`;
  }
}
```

### 3. Testing Configuration

```typescript
// test/helpers/test-config.ts
import { ConfigModule } from '@nestjs/config';

export const testConfig = () => 
  ConfigModule.forRoot({
    isGlobal: true,
    ignoreEnvFile: true, // Don't load .env in tests
    load: [
      () => ({
        DATABASE_HOST: 'localhost',
        DATABASE_PORT: 5432,
        DATABASE_USER: 'test',
        DATABASE_PASSWORD: 'test',
        DATABASE_NAME: 'test_db',
        JWT_SECRET: 'test-secret-key-minimum-32-chars',
      }),
    ],
  });

// Usage in tests
describe('UserService', () => {
  let service: UserService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      imports: [testConfig()],
      providers: [UserService],
    }).compile();

    service = module.get<UserService>(UserService);
  });
});
```

## Anti-Patterns

### ❌ DON'T: Direct process.env

```typescript
// BAD
const apiKey = process.env.OPENAI_API_KEY;
const dbHost = process.env.DATABASE_HOST;
```

### ❌ DON'T: String concatenation for nested paths

```typescript
// BAD
const host = process.env['database.host'];
```

### ❌ DON'T: Type casting without validation

```typescript
// BAD
const port = parseInt(process.env.PORT as string);
```

### ✅ DO: Use ConfigService

```typescript
// GOOD
constructor(private configService: ConfigService) {}

const apiKey = this.configService.getOrThrow<string>('OPENAI_API_KEY');
const dbHost = this.configService.get<string>('database.host');
const port = this.configService.get<number>('PORT', 3000);
```

## Security Checklist

- [ ] No secrets in code
- [ ] All secrets in environment variables
- [ ] Validation schema for all configs
- [ ] Use `getOrThrow` for required configs
- [ ] .env files gitignored
- [ ] .env.example committed as template
- [ ] Different configs per environment
- [ ] Secrets rotated regularly

---

**Remember**: Configuration is code. Treat it with the same rigor as your application logic.

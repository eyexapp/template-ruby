# Ruby Sinatra API Template

Production-ready, modular Sinatra API template with clean architecture, Sequel ORM, JWT authentication, and comprehensive testing.

## Tech Stack

| Category | Tool |
|----------|------|
| Framework | Sinatra 3.2 (Modular) |
| Server | Puma 6 |
| Database | PostgreSQL + Sequel ORM |
| JSON | Oj (fast native parser) |
| Auth | JWT (HS256) |
| Testing | RSpec + Rack::Test |
| Linting | RuboCop |
| Git Hooks | Lefthook |
| Container | Docker multi-stage + Compose |

## Quick Start

### Local Development

```bash
# Prerequisites: Ruby 3.2, PostgreSQL

# Install dependencies & setup database
bin/setup

# Start the server (with auto-reload)
bundle exec rerun 'puma -b tcp://0.0.0.0:3000'

# Or without auto-reload
bundle exec puma -b tcp://0.0.0.0:3000
```

### Docker

```bash
docker compose up
# App: http://localhost:3000
# DB: localhost:5432
```

## Project Structure

```
├── app/
│   ├── middleware/          # Rack middleware (error handling, logging, auth)
│   │   ├── error_handler.rb  # Catches exceptions → JSON error responses
│   │   ├── jwt_auth.rb       # JWT Bearer token verification
│   │   └── request_logger.rb # Request method + path + duration logging
│   ├── models/             # Sequel models (add your models here)
│   ├── routes/             # Sinatra route handlers (controller layer)
│   │   ├── base.rb           # Base class with JSON helpers
│   │   └── health.rb         # Health check endpoints
│   ├── serializers/        # JSON response serialization
│   │   └── base.rb           # BaseSerializer with .serialize/.collection
│   └── services/           # Business logic (service objects)
│       └── base.rb           # BaseService with .call + Result pattern
├── bin/
│   ├── console             # IRB/Pry with app loaded
│   └── setup               # One-command project setup
├── config/
│   ├── application.rb      # Boot sequence & Rack app builder
│   ├── database.rb         # Sequel database connection
│   ├── environment.rb      # Config class (ENV wrapper)
│   └── initializers/       # Library configuration
│       └── oj.rb
├── db/
│   ├── migrations/         # Sequel migrations (rake db:create_migration)
│   └── seeds.rb            # Seed data
├── spec/                   # RSpec test suite
│   ├── spec_helper.rb
│   ├── support/            # Shared test helpers
│   ├── routes/             # Route/endpoint tests
│   └── middleware/          # Middleware tests
├── app.rb                  # Entry point (ruby app.rb)
├── config.ru               # Rack config (puma starts here)
├── Gemfile                 # Dependencies
├── Rakefile                # Database & utility tasks
├── Dockerfile              # Multi-stage production build
└── docker-compose.yml      # App + PostgreSQL
```

## API Endpoints

| Method | Path | Description |
|--------|------|------------|
| GET | `/health` | Health check (always available) |
| GET | `/health/ready` | Readiness check (tests DB connection) |

## Adding New Features

### Create a Route

```ruby
# app/routes/users.rb
module Routes
  class Users < Base
    get "/" do
      users = DB[:users].all
      json_response(UserSerializer.collection(users))
    end

    post "/" do
      result = CreateUser.call(params: request_body)
      if result.success?
        json_response(UserSerializer.serialize(result.data), status: 201)
      else
        halt_json(422, result.error)
      end
    end
  end
end
```

Mount it in `config/application.rb`:
```ruby
map("/users") { run Routes::Users }
```

### Create a Model

```ruby
# app/models/user.rb
class User < Sequel::Model
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true

  def validate
    super
    validates_presence [:email, :name]
    validates_unique :email
  end
end
```

### Create a Service

```ruby
# app/services/create_user.rb
class CreateUser < Services::Base
  def initialize(params:)
    @params = params
  end

  def call
    user = User.create(@params)
    success(user)
  rescue Sequel::ValidationFailed => e
    failure(e.message)
  end
end
```

### Create a Serializer

```ruby
# app/serializers/user_serializer.rb
class UserSerializer
  include Serializers::Base
  attributes :id, :email, :name, :created_at
end
```

### Create a Migration

```bash
bundle exec rake db:create_migration[create_users]
```

## Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/routes/health_spec.rb

# Run with verbose output
bundle exec rspec --format documentation
```

## Linting

```bash
# Check for offenses
bundle exec rubocop

# Auto-fix
bundle exec rubocop --autocorrect-all
```

## Database Tasks

```bash
rake db:create              # Create database
rake db:drop                # Drop database
rake db:migrate             # Run pending migrations
rake db:rollback            # Rollback last migration
rake db:seed                # Run seed data
rake db:reset               # Drop + create + migrate + seed
rake db:create_migration[name]  # Generate migration file
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RACK_ENV` | `development` | Application environment |
| `PORT` | `3000` | Server port |
| `DATABASE_URL` | `postgres://localhost:5432/myapp_development` | PostgreSQL connection URL |
| `JWT_SECRET` | `change-me-in-production` | JWT signing secret |
| `JWT_EXPIRATION` | `3600` | JWT token TTL in seconds |

## Enabling JWT Authentication

Uncomment in `config/application.rb`:

```ruby
use Middleware::JwtAuth, skip: ["/health", "/health/ready"]
```

Protected routes will receive the decoded payload via `env['jwt.payload']`.

## License

MIT
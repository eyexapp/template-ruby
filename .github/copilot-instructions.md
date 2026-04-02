# Ruby Sinatra API Template — AI Agent Instructions

## Project Overview

This is a production-grade modular Sinatra API template using Ruby 3.2. It follows clean architecture principles with separated layers for routes, services, models, serializers, and middleware.

## Architecture

### Request Flow

```
Request → Puma → Rack Middleware Stack → Sinatra Route Handler → Response
                  ├── RequestLogger (logs method, path, duration)
                  ├── ErrorHandler (catches exceptions → JSON errors)
                  └── JwtAuth (optional, verifies Bearer tokens)
```

### Layer Responsibilities

- **Routes** (`app/routes/`): HTTP endpoint handlers. Inherit from `Routes::Base`. Handle request/response only — delegate logic to services.
- **Services** (`app/services/`): Business logic. Inherit from `Services::Base`. Use `.call()` pattern. Return `Result` structs (success/failure).
- **Models** (`app/models/`): Sequel ORM models. Database schema + validations + associations.
- **Serializers** (`app/serializers/`): Transform models/hashes to JSON-safe hashes. Include `Serializers::Base`. Define `attributes`.
- **Middleware** (`app/middleware/`): Rack middleware. Cross-cutting concerns (auth, logging, error handling).
- **Config** (`config/`): Boot sequence, database connection, environment config, library initializers.

### Key Patterns

#### Route Handler

```ruby
module Routes
  class ResourceName < Base
    get "/" do
      items = DB[:table].all
      json_response(items)
    end

    post "/" do
      result = CreateResource.call(params: request_body)
      result.success? ? json_response(result.data, status: 201) : halt_json(422, result.error)
    end
  end
end
```

#### Service Object

```ruby
class DoSomething < Services::Base
  def initialize(params:)
    @params = params
  end

  def call
    # business logic here
    success(result_data)
  rescue SomeError => e
    failure(e.message)
  end
end
```

#### Mounting Routes

New route files must be:
1. Required in `config/application.rb`
2. Mounted with `map("/path") { run Routes::ClassName }`

## File Naming Conventions

- All Ruby files: `snake_case.rb`
- One class/module per file
- Test files mirror source structure: `app/routes/health.rb` → `spec/routes/health_spec.rb`
- Migrations: `YYYYMMDDHHMMSS_description.rb`

## Key Files

| File | Purpose |
|------|---------|
| `config/application.rb` | Boot sequence, middleware stack, route mounting |
| `config/environment.rb` | Config class wrapping ENV variables |
| `config/database.rb` | Sequel database connection setup |
| `app/routes/base.rb` | Base route class with JSON helpers |
| `app/services/base.rb` | Base service with .call + Result pattern |
| `app/serializers/base.rb` | Base serializer with .serialize/.collection |
| `app/middleware/error_handler.rb` | Global exception → JSON error handler |
| `app/middleware/jwt_auth.rb` | JWT Bearer token verification (disabled by default) |
| `config.ru` | Rack entry point for Puma |
| `Rakefile` | Database tasks (create, migrate, seed, etc.) |

## Common Tasks

### Add a new endpoint
1. Create route file in `app/routes/`
2. Inherit from `Routes::Base`
3. Require it in `config/application.rb`
4. Mount with `map("/path") { run Routes::ClassName }`
5. Write tests in `spec/routes/`

### Add a database table
1. `bundle exec rake db:create_migration[create_table_name]`
2. Edit the migration file in `db/migrations/`
3. `bundle exec rake db:migrate`
4. Create model in `app/models/`

### Add a service
1. Create file in `app/services/`
2. Inherit from `Services::Base`
3. Implement `#call` method
4. Use `success(data)` / `failure(error)` returns

## Testing

- Framework: RSpec with Rack::Test
- Helper: `spec/support/api_helper.rb` provides `json_body`, `auth_header`, `post_json`, `put_json`
- Database cleanup: Transaction rollback per test (uncomment in spec_helper when DB is configured)
- Run: `bundle exec rspec`

## Dependencies

- **sinatra** + **sinatra-contrib**: Web framework (modular mode)
- **puma**: Multi-threaded web server
- **sequel** + **pg**: ORM + PostgreSQL adapter
- **oj**: Fast JSON parser/serializer
- **jwt**: JSON Web Token encoding/decoding
- **dotenv**: Environment variable loading
- **rubocop**: Code linting (with rspec + sequel plugins)
- **lefthook**: Git hooks (pre-commit rubocop, conventional commits)

## Important Notes

- JWT auth is **disabled by default** — uncomment in `config/application.rb` to enable
- Database connection gracefully skips if DATABASE_URL is not set
- Oj is configured in compat mode for broad compatibility
- Config class provides typed accessors — add new env vars there
- All errors are caught by ErrorHandler middleware and returned as structured JSON

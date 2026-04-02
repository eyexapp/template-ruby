# AGENTS.md — Ruby Sinatra Modular API

## Project Identity

| Key | Value |
|-----|-------|
| Framework | Sinatra (modular mode) + sinatra-contrib |
| Language | Ruby 3.2+ |
| Category | Backend REST API |
| Server | Puma (multi-threaded) |
| ORM | Sequel + pg adapter |
| Auth | JWT (disabled by default) |
| JSON | Oj (fast parser, compat mode) |
| Testing | RSpec + Rack::Test |
| Linting | RuboCop (with rspec + sequel plugins) |
| Git Hooks | Lefthook (pre-commit rubocop, conventional commits) |

---

## Architecture — Modular Sinatra with Service Objects

```
app/
├── routes/              ← PRESENTATION: HTTP endpoint handlers
│   ├── base.rb          ← Base route class with JSON helpers
│   ├── health.rb        ← Health check endpoint
│   └── items.rb         ← Feature CRUD routes
├── services/            ← BUSINESS LOGIC: Service objects (.call pattern)
│   ├── base.rb          ← Base with .call + Result struct
│   └── create_item.rb   ← One service per use case
├── models/              ← DOMAIN: Sequel ORM models
│   └── item.rb          ← Schema, validations, associations
├── serializers/         ← PRESENTATION: Model → JSON hash transforms
│   ├── base.rb          ← Base with .serialize / .collection
│   └── item_serializer.rb
└── middleware/           ← CROSS-CUTTING: Rack middleware
    ├── error_handler.rb ← Exception → JSON error responses
    ├── request_logger.rb← Logs method, path, duration
    └── jwt_auth.rb      ← JWT Bearer verification

config/
├── application.rb       ← Boot sequence, middleware stack, route mounting
├── environment.rb       ← Config class wrapping ENV variables
└── database.rb          ← Sequel database connection
```

### Request Flow
```
Request → Puma → Rack Middleware Stack → Sinatra Route Handler → Response
                  ├── RequestLogger
                  ├── ErrorHandler
                  └── JwtAuth (optional)
```

### Strict Layer Rules

| Layer | Can Import From | NEVER Imports |
|-------|----------------|---------------|
| `routes/` | services/, serializers/, models/ | middleware/ |
| `services/` | models/, config/ | routes/, serializers/ |
| `models/` | Sequel only | routes/, services/ |
| `serializers/` | models/ | services/, routes/ |
| `middleware/` | config/ | routes/, services/, models/ |

---

## Adding New Code — Where Things Go

### New Feature Checklist
1. **Migration**: `bundle exec rake db:create_migration[create_products]`
2. **Model**: `app/models/product.rb` — Sequel model with validations
3. **Service(s)**: `app/services/create_product.rb` — one per use case
4. **Serializer**: `app/serializers/product_serializer.rb`
5. **Routes**: `app/routes/products.rb` — inherits `Routes::Base`
6. **Mount**: Require + mount in `config/application.rb`
7. **Tests**: `spec/routes/products_spec.rb` + `spec/services/create_product_spec.rb`

### Route Handler Pattern
```ruby
module Routes
  class Products < Base
    get "/" do
      products = DB[:products].all
      json_response(ProductSerializer.collection(products))
    end

    post "/" do
      result = CreateProduct.call(params: request_body)
      if result.success?
        json_response(ProductSerializer.serialize(result.data), status: 201)
      else
        halt_json(422, result.error)
      end
    end

    get "/:id" do
      product = DB[:products].where(id: params[:id]).first
      halt_json(404, "Not found") unless product
      json_response(ProductSerializer.serialize(product))
    end
  end
end
```

### Service Object Pattern
```ruby
class CreateProduct < Services::Base
  def initialize(params:)
    @params = params
  end

  def call
    validate!
    product = DB[:products].insert(@params)
    success(product)
  rescue ValidationError => e
    failure(e.message)
  end

  private

  def validate!
    raise ValidationError, "name required" if @params[:name].to_s.empty?
  end
end
```

### Mounting Routes
```ruby
# config/application.rb
require_relative '../app/routes/products'

map("/api/v1/products") { run Routes::Products }
```

---

## Design & Architecture Principles

### Service Objects — Mandatory for Business Logic
- One service per use case (`CreateProduct`, `UpdateProduct`, `DeleteProduct`)
- All services inherit `Services::Base`
- Class-level `.call()` method delegates to instance `#call`
- Returns `Result` struct: `success(data)` or `failure(error)`
- Routes NEVER contain business logic

### Sequel ORM Patterns
```ruby
# Model with validations
class Product < Sequel::Model
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true

  def validate
    super
    validates_presence :name
    validates_min_length 1, :name
  end
end
```

### Configuration via Environment
```ruby
# config/environment.rb
class Config
  def self.database_url
    ENV.fetch("DATABASE_URL", "postgres://localhost/myapp_dev")
  end

  def self.jwt_secret
    ENV.fetch("JWT_SECRET", "dev-secret-change-me")
  end
end
```

---

## Error Handling

### ErrorHandler Middleware (Global)
```ruby
# All exceptions caught → structured JSON response
class ErrorHandler
  def call(env)
    @app.call(env)
  rescue Sequel::ValidationFailed => e
    json_error(422, e.message)
  rescue NotFoundError => e
    json_error(404, e.message)
  rescue StandardError => e
    log_error(e)
    json_error(500, "Internal server error")
  end
end
```

### Rules
- All errors caught by `ErrorHandler` middleware — returns JSON, never HTML
- Service failures returned as `Result.failure` (not exceptions)
- Domain exceptions for truly exceptional cases only
- Internal details logged but NEVER sent to client

---

## Code Quality

### Naming Conventions
| Artifact | Convention | Example |
|----------|-----------|---------|
| File | `snake_case.rb` | `create_product.rb` |
| Class | `PascalCase` | `CreateProduct` |
| Method | `snake_case` | `find_by_id` |
| Route class | `Routes::Name` | `Routes::Products` |
| Service class | Verb + noun | `CreateProduct` |
| Serializer | `NameSerializer` | `ProductSerializer` |
| Spec file | `*_spec.rb` | `products_spec.rb` |
| Migration | `YYYYMMDDHHMMSS_desc.rb` | `20240101_create_products.rb` |

### Ruby Style
- One class/module per file
- `frozen_string_literal: true` at top of every file
- `&&` / `||` instead of `and` / `or`
- Guard clauses instead of deep nesting
- `String#to_s` for nil-safe conversions

---

## Testing Strategy

| Level | What | Where | Tool |
|-------|------|-------|------|
| Unit | Services, models | `spec/services/`, `spec/models/` | RSpec |
| Route | HTTP endpoints | `spec/routes/` | RSpec + Rack::Test |
| Integration | Full middleware stack | `spec/integration/` | RSpec |

### Test Helpers
```ruby
# spec/support/api_helper.rb — included in route specs
def json_body
  JSON.parse(last_response.body, symbolize_names: true)
end

def post_json(path, body)
  post path, body.to_json, "CONTENT_TYPE" => "application/json"
end
```

### What MUST Be Tested
- All service objects: success and failure paths
- All route endpoints: status codes + response bodies
- Model validations: valid + invalid data
- Serializers: correct attribute selection
- Middleware: error handling for each exception type

---

## Security & Performance

### Security
- JWT auth disabled by default — enable in `config/application.rb`
- `ErrorHandler` NEVER exposes stack traces to clients
- Sequel parameterized queries — SQL injection prevention
- Sensitive config via ENV variables (never hardcoded)
- `Oj` in compat mode — safe JSON parsing

### Performance
- Puma multi-threaded — configure `threads` and `workers` for production
- Sequel connection pooling (automatic with `Sequel.connect`)
- Oj for fast JSON serialization (10x faster than stdlib)
- Lazy-load database connection — graceful startup without DB

---

## Commands

| Action | Command |
|--------|---------|
| Dev server | `bundle exec rackup` |
| Console | `bundle exec irb -r ./config/application` |
| Test | `bundle exec rspec` |
| Lint | `bundle exec rubocop` |
| Auto-fix | `bundle exec rubocop -a` |
| Create migration | `bundle exec rake db:create_migration[name]` |
| Migrate | `bundle exec rake db:migrate` |
| Rollback | `bundle exec rake db:rollback` |
| Seed | `bundle exec rake db:seed` |

---

## Prohibitions — NEVER Do These

1. **NEVER** put business logic in routes — delegate to services
2. **NEVER** use `Sinatra::Application` (classic mode) — modular mode only
3. **NEVER** use string interpolation in SQL — Sequel parameterized queries only
4. **NEVER** return HTML from API endpoints — JSON responses always
5. **NEVER** use `and` / `or` operators — use `&&` / `||`
6. **NEVER** use `rescue Exception` — use `rescue StandardError`
7. **NEVER** skip `frozen_string_literal: true` comment
8. **NEVER** expose stack traces to clients — `ErrorHandler` catches all
9. **NEVER** use `require` without `require_relative` in app code
10. **NEVER** skip RuboCop — lefthook enforces on every commit

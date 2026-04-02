---
name: security-performance
type: knowledge
version: 1.0.0
agent: CodeActAgent
triggers:
  - security
  - performance
  - n+1
  - caching
  - jwt
  - brakeman
---

# Security & Performance — Ruby on Rails

## Performance

### N+1 Query Prevention

```ruby
# ❌ N+1
users = User.all
users.each { |u| u.posts.count }

# ✅ Eager loading
users = User.includes(:posts).all

# Bullet gem for detection in development
# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
end
```

### Database Optimization

```ruby
# Counter caches
belongs_to :user, counter_cache: true

# Select only needed columns
User.select(:id, :name, :email).where(active: true)

# Batch processing
User.find_each(batch_size: 500) do |user|
  user.update_stats!
end
```

### Fragment Caching

```ruby
# Russian doll caching (API responses)
Rails.cache.fetch(["user", user.id, user.updated_at]) do
  UserSerializer.new(user).serializable_hash
end
```

## Security

### Strong Parameters

```ruby
# Always whitelist params
def user_params
  params.require(:user).permit(:name, :email, :password)
end
```

### Authentication (JWT)

```ruby
# jwt gem
class AuthenticationService
  SECRET = Rails.application.credentials.jwt_secret

  def self.encode(payload)
    JWT.encode(payload.merge(exp: 24.hours.from_now.to_i), SECRET)
  end

  def self.decode(token)
    JWT.decode(token, SECRET, true, algorithm: "HS256").first
  rescue JWT::DecodeError
    nil
  end
end
```

### Brakeman (Security Scanner)

```bash
bundle exec brakeman -q --no-summary
```

### SQL Injection Prevention

```ruby
# ✅ Parameterized
User.where("name LIKE ?", "%#{sanitize_sql_like(query)}%")

# ❌ Never interpolate
User.where("name = '#{params[:name]}'")  # SQL injection!
```

### Rate Limiting (Rack::Attack)

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle("api/ip", limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/api")
end
```

### CORS

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://myapp.com"
    resource "/api/*", headers: :any, methods: [:get, :post, :put, :delete]
  end
end
```

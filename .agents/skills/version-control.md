---
name: version-control
type: knowledge
version: 1.0.0
agent: CodeActAgent
triggers:
  - git
  - commit
  - ci
  - deploy
  - docker
---

# Version Control — Ruby on Rails

## Commits

- `feat(users): add search service with pg_search`
- `fix(auth): handle expired JWT gracefully`
- `db: add index on users.email`

## CI Pipeline

```bash
bundle install --jobs 4 --retry 3
bin/rails db:create db:migrate
bundle exec rubocop --parallel
bundle exec rspec
```

## Migrations

```bash
bin/rails generate migration CreateUsers name:string email:string:index
bin/rails db:migrate
bin/rails db:rollback STEP=1
```

## Docker

```dockerfile
FROM ruby:3.3-slim
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test
COPY . .
RUN bin/rails assets:precompile 2>/dev/null || true
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
```

## .gitignore

```
/log/*
/tmp/*
/storage/*
.env
/db/*.sqlite3
/public/assets
```

## Environments

```yaml
# config/database.yml
production:
  url: <%= ENV["DATABASE_URL"] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

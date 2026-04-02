---
name: code-quality
type: knowledge
version: 1.0.0
agent: CodeActAgent
triggers:
  - code quality
  - naming
  - rubocop
  - style
  - conventions
---

# Code Quality — Ruby on Rails 8

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Class | CamelCase | `UserService` |
| Method | snake_case | `find_by_email` |
| Variable | snake_case | `user_count` |
| Constant | SCREAMING_SNAKE | `MAX_PAGE_SIZE` |
| File | snake_case | `user_service.rb` |
| Table | plural snake_case | `users` |
| Migration | descriptive | `create_users` |
| Predicate | ends with ? | `active?` |
| Dangerous | ends with ! | `save!` |

## RuboCop Configuration

```yaml
# .rubocop.yml
require:
  - rubocop-rails
  - rubocop-rspec

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.3
  Exclude:
    - db/schema.rb
    - bin/**/*
    - vendor/**/*

Style/Documentation:
  Enabled: false

Metrics/MethodLength:
  Max: 20

Rails/HasManyOrHasOneDependent:
  Enabled: true
```

## Model Validations

```ruby
class User < ApplicationRecord
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { in: 2..100 }

  before_save :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip
  end
end
```

## Error Handling

```ruby
class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable

  private

  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def unprocessable(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end
end
```

## Serialization (jsonapi-serializer)

```ruby
class UserSerializer
  include JSONAPI::Serializer

  attributes :name, :email, :created_at
  has_many :posts
end
```

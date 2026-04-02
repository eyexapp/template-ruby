---
name: architecture
type: knowledge
version: 1.0.0
agent: CodeActAgent
triggers:
  - architecture
  - rails
  - ruby
  - mvc
  - activerecord
---

# Architecture — Ruby on Rails 8

## Rails MVC Structure

```
app/
├── controllers/
│   ├── application_controller.rb
│   └── api/v1/
│       └── users_controller.rb
├── models/
│   ├── application_record.rb
│   └── user.rb
├── services/                      ← Business logic (POROs)
│   └── users/
│       ├── create_service.rb
│       └── search_service.rb
├── serializers/                   ← JSON serialization
│   └── user_serializer.rb
├── jobs/                          ← Solid Queue background
│   └── send_welcome_email_job.rb
├── mailers/
│   └── user_mailer.rb
└── views/                         ← API-only: no views
config/
├── routes.rb
├── database.yml
└── initializers/
db/
├── migrate/
│   ├── 20240101000000_create_users.rb
│   └── 20240102000000_add_index_to_users_email.rb
└── schema.rb
```

## API Controller

```ruby
module Api
  module V1
    class UsersController < ApplicationController
      def index
        users = User.page(params[:page]).per(20)
        render json: UserSerializer.new(users).serializable_hash
      end

      def create
        result = Users::CreateService.call(user_params)
        if result.success?
          render json: UserSerializer.new(result.user).serializable_hash, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :password)
      end
    end
  end
end
```

## Service Object Pattern

```ruby
module Users
  class CreateService
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params
    end

    def call
      user = User.new(@params)
      if user.save
        UserMailer.welcome(user).deliver_later
        OpenStruct.new(success?: true, user: user)
      else
        OpenStruct.new(success?: false, errors: user.errors.full_messages)
      end
    end
  end
end
```

## ActiveRecord Model

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :posts, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
end
```

## Routes

```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :show, :create, :update, :destroy]
    end
  end
end
```

## Rules

- Controller → Service → Model layering.
- Service objects for complex business logic (not in controllers or models).
- Strong parameters for mass assignment protection.
- API versioning via namespaced routes.
- Solid Queue for background jobs (Rails 8 default).

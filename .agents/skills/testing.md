---
name: testing
type: knowledge
version: 1.0.0
agent: CodeActAgent
triggers:
  - test
  - rspec
  - factory bot
  - minitest
  - request spec
---

# Testing — Ruby (RSpec + FactoryBot)

## Model Specs

```ruby
RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe "associations" do
    it { is_expected.to have_many(:posts).dependent(:destroy) }
  end

  describe "#active?" do
    it "returns true for active users" do
      user = build(:user, active: true)
      expect(user).to be_active
    end
  end
end
```

## Request Specs

```ruby
RSpec.describe "Api::V1::Users", type: :request do
  describe "POST /api/v1/users" do
    let(:valid_params) { { user: attributes_for(:user) } }

    it "creates a user" do
      expect {
        post "/api/v1/users", params: valid_params, as: :json
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns errors for invalid params" do
      post "/api/v1/users", params: { user: { name: "" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

## Service Specs

```ruby
RSpec.describe Users::CreateService do
  describe ".call" do
    let(:params) { attributes_for(:user) }

    it "creates user and enqueues welcome email" do
      result = described_class.call(params)

      expect(result).to be_success
      expect(result.user).to be_persisted
      expect(UserMailer).to have_enqueued_mail(:welcome)
    end
  end
end
```

## FactoryBot

```ruby
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }

    trait :admin do
      role { :admin }
    end

    trait :with_posts do
      after(:create) do |user|
        create_list(:post, 3, user: user)
      end
    end
  end
end
```

## Rules

- RSpec: `describe` for class/method, `context` for scenarios, `it` for expectations.
- `build` for unit tests (no DB), `create` for integration.
- Request specs over controller specs (Rails team recommendation).
- `bundle exec rspec` — run all tests.
- `bundle exec rspec spec/models/` — run model specs only.

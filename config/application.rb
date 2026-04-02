# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default, ENV.fetch('RACK_ENV', 'development').to_sym)

# Load configuration
require_relative 'environment'
require_relative 'initializers/oj'

# Connect to database (skip if DATABASE_URL is not set — allows running without DB)
if ENV['DATABASE_URL'] || !Config.test?
  begin
    require_relative 'database'
  rescue Sequel::DatabaseConnectionError => e
    warn "WARNING: Could not connect to database: #{e.message}"
  end
end

# Load application code
require_relative '../app/middleware/error_handler'
require_relative '../app/middleware/request_logger'
require_relative '../app/middleware/jwt_auth'
require_relative '../app/serializers/base'
require_relative '../app/services/base'
require_relative '../app/routes/base'
require_relative '../app/routes/health'

# Load models
Dir[File.join(__dir__, '..', 'app', 'models', '*.rb')].each { |f| require f }

# Build the Rack application
App = Rack::Builder.new do
  use Middleware::RequestLogger unless Config.test?
  use Middleware::ErrorHandler
  # use Middleware::JwtAuth, skip: ["/health", "/health/ready"]

  map('/health') { run Routes::Health }
  map('/') { run Routes::Base }
end

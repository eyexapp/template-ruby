# frozen_string_literal: true

require 'dotenv'

# Load environment-specific .env file
Dotenv.load(".env.#{ENV.fetch('RACK_ENV', 'development')}", '.env')

module Config
  module_function

  def app_env
    ENV.fetch('RACK_ENV', 'development')
  end

  def port
    ENV.fetch('PORT', '3000').to_i
  end

  def database_url
    ENV.fetch('DATABASE_URL', "postgres://localhost:5432/myapp_#{app_env}")
  end

  def jwt_secret
    ENV.fetch('JWT_SECRET', 'change-me-in-production')
  end

  def jwt_expiration
    ENV.fetch('JWT_EXPIRATION', '3600').to_i
  end

  def development?
    app_env == 'development'
  end

  def test?
    app_env == 'test'
  end

  def production?
    app_env == 'production'
  end
end

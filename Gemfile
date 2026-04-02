# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 3.2.0'

# Web framework
gem 'sinatra', '~> 3.1'
gem 'sinatra-contrib', '~> 3.1'

# Web server
gem 'puma', '~> 6.4'

# Database
gem 'pg', '~> 1.5'
gem 'sequel', '~> 5.84'

# JSON
gem 'oj', '~> 3.16'

# Auth
gem 'jwt', '~> 2.9'

# Configuration
gem 'dotenv', '~> 3.1'

# Middleware
gem 'rack-contrib', '~> 2.5'

group :development do
  gem 'rerun'
  gem 'rubocop', '~> 1.68', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-sequel', require: false
end

group :development, :test do
  gem 'pry'
end

group :test do
  gem 'database_cleaner-sequel', '~> 2.0'
  gem 'factory_bot', '~> 6.5'
  gem 'faker', '~> 3.5'
  gem 'rack-test', '~> 2.2'
  gem 'rspec', '~> 3.13'
end

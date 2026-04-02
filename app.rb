# frozen_string_literal: true

require_relative 'config/application'

# Direct execution: ruby app.rb
Rack::Handler::Puma.run(App, Port: Config.port, Host: '0.0.0.0') if __FILE__ == $PROGRAM_NAME

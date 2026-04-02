# frozen_string_literal: true

module Middleware
  class ErrorHandler
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue JWT::DecodeError => e
      error_response(401, "Invalid token: #{e.message}", code: 'AUTH_INVALID_TOKEN')
    rescue Sequel::ValidationFailed => e
      error_response(422, e.message, code: 'VALIDATION_FAILED')
    rescue Sequel::NoMatchingRow
      error_response(404, 'Resource not found', code: 'NOT_FOUND')
    rescue StandardError => e
      log_error(env, e)
      message = Config.production? ? 'Internal server error' : e.message
      error_response(500, message, code: 'INTERNAL_ERROR')
    end

    private

    def error_response(status, message, code: nil)
      body = Oj.dump({ error: { message: message, code: code || status, status: status } })
      [status, { 'content-type' => 'application/json' }, [body]]
    end

    def log_error(env, error)
      warn "[ERROR] #{env['REQUEST_METHOD']} #{env['PATH_INFO']} - #{error.class}: #{error.message}"
      warn error.backtrace&.first(10)&.join("\n") if error.backtrace
    end
  end
end

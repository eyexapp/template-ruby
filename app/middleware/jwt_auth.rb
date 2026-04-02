# frozen_string_literal: true

require 'jwt'

module Middleware
  class JwtAuth
    BEARER_REGEX = /\ABearer\s+(.+)\z/

    def initialize(app, skip: [])
      @app = app
      @skip = skip
    end

    def call(env)
      path = env['PATH_INFO']
      return @app.call(env) if skip_path?(path)

      token = extract_token(env)
      return unauthorized('Missing authorization header') unless token

      payload = decode_token(token)
      return unauthorized('Invalid or expired token') unless payload

      env['jwt.payload'] = payload
      @app.call(env)
    end

    private

    def skip_path?(path)
      @skip.any? { |prefix| path.start_with?(prefix) }
    end

    def extract_token(env)
      header = env['HTTP_AUTHORIZATION']
      return unless header

      match = header.match(BEARER_REGEX)
      match&.[](1)
    end

    def decode_token(token)
      JWT.decode(token, Config.jwt_secret, true, algorithm: 'HS256').first
    rescue JWT::DecodeError
      nil
    end

    def unauthorized(message)
      body = Oj.dump({ error: { message: message, code: 'UNAUTHORIZED', status: 401 } })
      [401, { 'content-type' => 'application/json' }, [body]]
    end
  end
end

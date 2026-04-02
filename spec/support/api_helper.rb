# frozen_string_literal: true

module ApiHelper
  def app
    App
  end

  def json_body
    Oj.load(last_response.body, symbol_keys: true)
  end

  def auth_header(payload = { sub: 1 })
    token = JWT.encode(payload, Config.jwt_secret, 'HS256')
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end

  def post_json(path, body = {}, headers = {})
    post path, Oj.dump(body), { 'CONTENT_TYPE' => 'application/json' }.merge(headers)
  end

  def put_json(path, body = {}, headers = {})
    put path, Oj.dump(body), { 'CONTENT_TYPE' => 'application/json' }.merge(headers)
  end
end

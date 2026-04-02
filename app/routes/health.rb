# frozen_string_literal: true

module Routes
  class Health < Sinatra::Base
    get '/' do
      content_type :json
      Oj.dump({ status: 'ok', timestamp: Time.now.iso8601 })
    end

    get '/ready' do
      content_type :json
      begin
        DB.test_connection
        Oj.dump({ status: 'ok', database: 'connected' })
      rescue StandardError => e
        status 503
        Oj.dump({ status: 'error', database: e.message })
      end
    end
  end
end

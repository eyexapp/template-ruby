# frozen_string_literal: true

module Routes
  class Base < Sinatra::Base
    configure do
      set :show_exceptions, false
      set :raise_errors, false
      set :dump_errors, false
    end

    before do
      content_type :json
    end

    helpers do
      def json_response(data, status: 200)
        halt status, Oj.dump(data)
      end

      def halt_json(status, message, code: nil)
        halt status, Oj.dump({
                               error: {
                                 message: message,
                                 code: code || status,
                                 status: status
                               }
                             })
      end

      def request_body
        @request_body ||= begin
          body = request.body.read
          body.empty? ? {} : Oj.load(body, symbol_keys: true)
        rescue Oj::ParseError
          halt_json(400, 'Invalid JSON')
        end
      end

      def pagination_params
        page = [params.fetch('page', 1).to_i, 1].max
        per_page = params.fetch('per_page', 25).to_i.clamp(1, 100)
        { page: page, per_page: per_page, offset: (page - 1) * per_page }
      end
    end

    # Catch-all for undefined routes on this mount
    not_found do
      Oj.dump({ error: { message: 'Not found', code: 404, status: 404 } })
    end
  end
end

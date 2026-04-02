# frozen_string_literal: true

RSpec.describe Middleware::ErrorHandler do
  let(:error_app) do
    failing_app = ->(_env) { raise StandardError, 'Something broke' }
    Rack::Builder.new do
      use Middleware::ErrorHandler
      run failing_app
    end
  end

  def app
    error_app
  end

  describe 'when an exception occurs' do
    before { get '/' }

    it 'returns 500 status with JSON content type' do
      expect(last_response.status).to eq(500)
      expect(last_response.content_type).to include('application/json')
    end

    it 'returns structured error body' do
      body = Oj.load(last_response.body, symbol_keys: true)
      expect(body[:error]).to include(message: 'Something broke', code: 'INTERNAL_ERROR', status: 500)
    end
  end

  describe 'when no exception occurs' do
    let(:ok_app) do
      success_app = ->(_env) { [200, { 'content-type' => 'application/json' }, ['{"ok":true}']] }
      Rack::Builder.new do
        use Middleware::ErrorHandler
        run success_app
      end
    end

    def app
      ok_app
    end

    it 'passes through normally' do
      get '/'

      expect(last_response.status).to eq(200)
    end
  end
end

# frozen_string_literal: true

# Stub DB constant for tests when database is not available
DB = Class.new do
  def test_connection
    true
  end
end.new unless defined?(DB)

RSpec.describe Routes::Health do
  describe 'GET /health' do
    it 'returns ok status' do
      get '/health'

      expect(last_response.status).to eq(200)
      expect(json_body[:status]).to eq('ok')
      expect(json_body[:timestamp]).not_to be_nil
    end
  end

  describe 'GET /health/ready' do
    context 'when database is available' do
      before do
        allow(DB).to receive(:test_connection).and_return(true)
      end

      it 'returns connected status' do
        get '/health/ready'

        expect(last_response.status).to eq(200)
        expect(json_body[:status]).to eq('ok')
        expect(json_body[:database]).to eq('connected')
      end
    end

    context 'when database is unavailable' do
      before do
        allow(DB).to receive(:test_connection).and_raise(Sequel::DatabaseConnectionError.new('Connection refused'))
      end

      it 'returns error status' do
        get '/health/ready'

        expect(last_response.status).to eq(503)
        expect(json_body[:status]).to eq('error')
      end
    end
  end
end

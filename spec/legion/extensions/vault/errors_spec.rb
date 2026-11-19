# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Errors do
  describe Legion::Extensions::Vault::Errors::AuthUnresolved do
    it 'is a StandardError' do
      expect(described_class.new('no credentials')).to be_a(StandardError)
    end
  end

  describe Legion::Extensions::Vault::Errors::ReadOnlyError do
    it 'is a StandardError' do
      expect(described_class.new('write disabled')).to be_a(StandardError)
    end
  end

  describe Legion::Extensions::Vault::Errors::APIError do
    it 'carries the numeric code and message' do
      error = described_class.new(403, 'permission denied')

      expect(error.code).to eq(403)
      expect(error.message).to eq('permission denied')
      expect(error).to be_a(StandardError)
    end
  end

  describe Legion::Extensions::Vault::Errors::Raiser do
    let(:stubs) { Faraday::Adapter::Test::Stubs.new }

    def raiser_connection
      Faraday.new(url: 'http://127.0.0.1:8200') do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.response :vault_raiser
        conn.adapter :test, stubs
      end
    end

    it 'passes 2xx responses through' do
      stubs.get('/v1/ok') do
        [200, { 'Content-Type' => 'application/json' }, { 'key' => 'value' }.to_json]
      end

      response = raiser_connection.get('/v1/ok')

      expect(response.status).to eq(200)
    end

    it 'passes 204 empty responses through' do
      stubs.delete('/v1/gone') { [204, {}, ''] }

      response = raiser_connection.delete('/v1/gone')

      expect(response.status).to eq(204)
    end

    it 'raises APIError with the status and Vault message on 4xx' do
      stubs.post('/v1/deny') do
        [403, { 'Content-Type' => 'application/json' }, { 'errors' => ['permission denied'] }.to_json]
      end

      expect { raiser_connection.post('/v1/deny') }
        .to raise_error(Legion::Extensions::Vault::Errors::APIError) do |error|
          expect(error.code).to eq(403)
          expect(error.message).to eq('permission denied')
        end
    end

    it 'raises APIError with a generic message on 5xx without an errors body' do
      stubs.get('/v1/broken') { [500, { 'Content-Type' => 'application/json' }, ''] }

      expect { raiser_connection.get('/v1/broken') }
        .to raise_error(Legion::Extensions::Vault::Errors::APIError) do |error|
          expect(error.code).to eq(500)
        end
    end
  end
end

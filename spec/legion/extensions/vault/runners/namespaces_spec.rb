# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Runners::Namespaces do
  let(:client) { Legion::Extensions::Vault::Client.new(token: 'test-token') }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new(url: 'http://127.0.0.1:8200') do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :test, stubs
    end
  end

  before { allow(client).to receive(:connection).and_return(test_connection) }

  describe '#list_namespaces' do
    it 'returns the normalized namespace list' do
      stubs.get('/v1/sys/namespaces') do
        [200, { 'Content-Type' => 'application/json' }, { 'keys' => ['ns1/', 'ns2/'] }.to_json]
      end

      expect(client.list_namespaces).to eq(keys: ['ns1/', 'ns2/'])
    end
  end

  describe '#get_namespace' do
    it 'returns the normalized namespace details' do
      stubs.get('/v1/sys/namespaces/myns') do
        [200, { 'Content-Type' => 'application/json' }, { 'path' => 'myns/', 'id' => 'abc123' }.to_json]
      end

      expect(client.get_namespace(name: 'myns')).to eq(path: 'myns/', id: 'abc123')
    end
  end

  describe '#create_namespace' do
    it 'returns the normalized body' do
      stubs.post('/v1/sys/namespaces/new-ns') do
        [200, { 'Content-Type' => 'application/json' }, {}.to_json]
      end

      expect(client.create_namespace(name: 'new-ns')).to eq({})
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.create_namespace(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#delete_namespace' do
    it 'returns the status for empty-body responses' do
      stubs.delete('/v1/sys/namespaces/old-ns') { [204, {}, ''] }

      expect(client.delete_namespace(name: 'old-ns')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.delete_namespace(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end
end

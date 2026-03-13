# frozen_string_literal: true

RSpec.describe Legion::Extensions::Vault::Runners::Kv do
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

  describe '#read_secret' do
    it 'reads a secret from KV v2' do
      stubs.get('/v1/secret/data/my/secret') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'data' => { 'foo' => 'bar' } } }]
      end
      result = client.read_secret(path: 'my/secret')
      expect(result[:result]['data']['data']['foo']).to eq('bar')
    end
  end

  describe '#write_secret' do
    it 'writes a secret to KV v2' do
      stubs.post('/v1/secret/data/my/secret') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'version' => 1 } }]
      end
      result = client.write_secret(path: 'my/secret', data: { foo: 'bar' })
      expect(result[:result]['data']['version']).to eq(1)
    end
  end

  describe '#delete_secret' do
    it 'soft-deletes a secret' do
      stubs.delete('/v1/secret/data/my/secret') { [204, {}, ''] }
      result = client.delete_secret(path: 'my/secret')
      expect(result[:result]).to be true
    end
  end

  describe '#list_secrets' do
    it 'lists secrets at a path' do
      stubs.get('/v1/secret/metadata/my') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => %w[secret1 secret2] } }]
      end
      result = client.list_secrets(path: 'my')
      expect(result[:result]['data']['keys']).to include('secret1')
    end
  end

  describe '#read_metadata' do
    it 'reads secret metadata' do
      stubs.get('/v1/secret/metadata/my/secret') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'max_versions' => 10 } }]
      end
      result = client.read_metadata(path: 'my/secret')
      expect(result[:result]['data']['max_versions']).to eq(10)
    end
  end

  describe '#delete_metadata' do
    it 'permanently deletes all versions' do
      stubs.delete('/v1/secret/metadata/my/secret') { [204, {}, ''] }
      result = client.delete_metadata(path: 'my/secret')
      expect(result[:result]).to be true
    end
  end
end

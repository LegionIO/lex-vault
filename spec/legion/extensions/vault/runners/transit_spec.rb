# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Runners::Transit do
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

  describe '#create_key' do
    it 'returns the status for empty-body responses' do
      stubs.post('/v1/transit/keys/my-key') { [204, {}, ''] }

      expect(client.create_key(name: 'my-key')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.create_key(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#read_key' do
    it 'returns the normalized key information' do
      stubs.get('/v1/transit/keys/my-key') do
        [200, { 'Content-Type' => 'application/json' },
         { 'data' => { 'name' => 'my-key', 'type' => 'aes256-gcm96' } }.to_json]
      end

      expect(client.read_key(name: 'my-key')).to eq(data: { name: 'my-key', type: 'aes256-gcm96' })
    end
  end

  describe '#list_keys' do
    it 'returns the normalized key list' do
      stubs.get('/v1/transit/keys') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => ['my-key'] } }.to_json]
      end

      expect(client.list_keys).to eq(data: { keys: ['my-key'] })
    end
  end

  describe '#encrypt' do
    it 'returns the normalized ciphertext' do
      stubs.post('/v1/transit/encrypt/my-key') do
        [200, { 'Content-Type' => 'application/json' },
         { 'data' => { 'ciphertext' => 'vault:v1:abc123' } }.to_json]
      end

      expect(client.encrypt(name: 'my-key', plaintext: 'dGVzdA=='))
        .to eq(data: { ciphertext: 'vault:v1:abc123' })
    end
  end

  describe '#decrypt' do
    it 'returns the normalized plaintext' do
      stubs.post('/v1/transit/decrypt/my-key') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'plaintext' => 'dGVzdA==' } }.to_json]
      end

      expect(client.decrypt(name: 'my-key', ciphertext: 'vault:v1:abc123'))
        .to eq(data: { plaintext: 'dGVzdA==' })
    end
  end

  describe '#sign' do
    it 'returns the normalized signature' do
      stubs.post('/v1/transit/sign/my-key') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'signature' => 'vault:v1:sig' } }.to_json]
      end

      expect(client.sign(name: 'my-key', input: 'dGVzdA==')).to eq(data: { signature: 'vault:v1:sig' })
    end
  end

  describe '#hash_data' do
    it 'returns the normalized hash' do
      stubs.post('/v1/transit/hash/sha2-256') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'sum' => 'abc123def' } }.to_json]
      end

      expect(client.hash_data(input: 'dGVzdA==')).to eq(data: { sum: 'abc123def' })
    end
  end

  describe '#random_bytes' do
    it 'returns the normalized random bytes' do
      stubs.post('/v1/transit/random/32') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'random_bytes' => 'cmFuZG9t' } }.to_json]
      end

      expect(client.random_bytes).to eq(data: { random_bytes: 'cmFuZG9t' })
    end
  end
end

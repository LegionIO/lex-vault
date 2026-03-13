# frozen_string_literal: true

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
    it 'creates a named encryption key' do
      stubs.post('/v1/transit/keys/my-key') { [204, {}, ''] }
      result = client.create_key(name: 'my-key')
      expect(result[:result]).to be true
    end
  end

  describe '#read_key' do
    it 'reads key information' do
      stubs.get('/v1/transit/keys/my-key') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'name' => 'my-key', 'type' => 'aes256-gcm96' } }]
      end
      result = client.read_key(name: 'my-key')
      expect(result[:result]['data']['name']).to eq('my-key')
    end
  end

  describe '#list_keys' do
    it 'lists all transit keys' do
      stubs.get('/v1/transit/keys') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => ['my-key'] } }]
      end
      result = client.list_keys
      expect(result[:result]['data']['keys']).to include('my-key')
    end
  end

  describe '#encrypt' do
    it 'encrypts plaintext' do
      stubs.post('/v1/transit/encrypt/my-key') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'ciphertext' => 'vault:v1:abc123' } }]
      end
      result = client.encrypt(name: 'my-key', plaintext: 'dGVzdA==')
      expect(result[:result]['data']['ciphertext']).to start_with('vault:v1:')
    end
  end

  describe '#decrypt' do
    it 'decrypts ciphertext' do
      stubs.post('/v1/transit/decrypt/my-key') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'plaintext' => 'dGVzdA==' } }]
      end
      result = client.decrypt(name: 'my-key', ciphertext: 'vault:v1:abc123')
      expect(result[:result]['data']['plaintext']).to eq('dGVzdA==')
    end
  end

  describe '#sign' do
    it 'signs input data' do
      stubs.post('/v1/transit/sign/my-key') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'signature' => 'vault:v1:sig' } }]
      end
      result = client.sign(name: 'my-key', input: 'dGVzdA==')
      expect(result[:result]['data']['signature']).to start_with('vault:v1:')
    end
  end

  describe '#hash_data' do
    it 'hashes input data' do
      stubs.post('/v1/transit/hash/sha2-256') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'sum' => 'abc123def' } }]
      end
      result = client.hash_data(input: 'dGVzdA==')
      expect(result[:result]['data']['sum']).to eq('abc123def')
    end
  end

  describe '#random_bytes' do
    it 'generates random bytes' do
      stubs.post('/v1/transit/random/32') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'random_bytes' => 'cmFuZG9t' } }]
      end
      result = client.random_bytes
      expect(result[:result]['data']['random_bytes']).not_to be_nil
    end
  end
end

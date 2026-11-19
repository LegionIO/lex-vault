# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Runners::Consul do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new(url: 'http://127.0.0.1:8200') do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :test, stubs
    end
  end

  before { allow(described_class).to receive(:connection).and_return(test_connection) }

  describe '#configure' do
    it 'sends the consul server config with the business token as token on the wire' do
      body = nil
      stubs.post('/v1/consul/config/access') do |env|
        body = env[:body]
        [204, {}, '']
      end

      expect(described_class.configure(address: 'consul.internal:8501', consul_token: 'c.token'))
        .to eq(status: 204)
      expect(Legion::JSON.load(body)).to eq(address: 'consul.internal:8501', scheme: 'https', token: 'c.token')
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { described_class.configure(address: 'x', consul_token: 'y', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#create_role' do
    it 'sends the role schema and returns the status' do
      body = nil
      stubs.post('/v1/consul/roles/legion-client') do |env|
        body = env[:body]
        [204, {}, '']
      end

      expect(described_class.create_role(name: 'legion-client', consul_policies: %w[default])).to eq(status: 204)
      expect(Legion::JSON.load(body)).to eq(
        partition: 'default', local: true, ttl: '31d', max_ttl: '1y', consul_policies: %w[default]
      )
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { described_class.create_role(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#read_role' do
    it 'returns the normalized role' do
      stubs.get('/v1/consul/roles/legion-client') do
        [200, { 'Content-Type' => 'application/json' },
         { 'data' => { 'name' => 'legion-client', 'consul_policies' => ['default'] } }.to_json]
      end

      expect(described_class.read_role(name: 'legion-client'))
        .to eq(data: { name: 'legion-client', consul_policies: ['default'] })
    end
  end

  describe '#list_roles' do
    it 'returns the normalized role list' do
      stubs.get('/v1/consul/roles') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => ['legion-client'] } }.to_json]
      end

      expect(described_class.list_roles).to eq(data: { keys: ['legion-client'] })
    end
  end

  describe '#delete_role' do
    it 'returns the status for empty-body responses' do
      stubs.delete('/v1/consul/roles/legion-client') { [204, {}, ''] }

      expect(described_class.delete_role(name: 'legion-client')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { described_class.delete_role(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#generate_credential' do
    it 'returns the normalized credential with lease metadata' do
      stubs.get('/v1/consul/creds/legion-client') do
        [200, { 'Content-Type' => 'application/json' },
         { 'lease_id' => 'auth/consul/creds/legion-client', 'lease_duration' => 2_592_000,
           'renewable' => true, 'data' => { 'token' => 'c.minted' } }.to_json]
      end

      expect(described_class.generate_credential(role: 'legion-client')).to eq(
        lease_id: 'auth/consul/creds/legion-client', lease_duration: 2_592_000,
        renewable: true, data: { token: 'c.minted' }
      )
    end
  end
end

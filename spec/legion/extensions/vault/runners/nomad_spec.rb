# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Runners::Nomad do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new(url: 'http://127.0.0.1:8200') do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :test, stubs
    end
  end

  before { allow(described_class).to receive(:connection).and_return(test_connection) }

  describe '#create_role' do
    it 'posts the role schema and returns the status' do
      body = nil
      stubs.post('/v1/nomad/role/legion') do |env|
        body = env[:body]
        [204, {}, '']
      end

      expect(described_class.create_role(name: 'legion', policies: %w[global-read])).to eq(status: 204)
      expect(Legion::JSON.load(body)).to eq(name: 'legion', policies: %w[global-read], global: true, type: 'management')
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { described_class.create_role(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#read_role' do
    it 'GETs the role (corrected: the original implementation POSTed)' do
      method = nil
      stubs.get('/v1/nomad/role/legion') do |env|
        method = env[:method]
        [200, { 'Content-Type' => 'application/json' },
         { 'data' => { 'name' => 'legion', 'policies' => ['global-read'] } }.to_json]
      end

      expect(described_class.read_role(name: 'legion')).to eq(data: { name: 'legion', policies: ['global-read'] })
      expect(method).to eq(:get)
    end
  end

  describe '#list_roles' do
    it 'returns the normalized role list' do
      stubs.get('/v1/nomad/role') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => ['legion'] } }.to_json]
      end

      expect(described_class.list_roles).to eq(data: { keys: ['legion'] })
    end
  end

  describe '#delete_role' do
    it 'returns the status for empty-body responses' do
      stubs.delete('/v1/nomad/role/legion') { [204, {}, ''] }

      expect(described_class.delete_role(name: 'legion')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { described_class.delete_role(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#generate_credential' do
    it 'POSTs to /cred/{accessor} (corrected: the original implementation GET the role path)' do
      method = nil
      stubs.post('/v1/nomad/cred/legion') do |env|
        method = env[:method]
        [200, { 'Content-Type' => 'application/json' },
         { 'lease_id' => 'auth/nomad/cred/legion', 'lease_duration' => 3600,
           'renewable' => true, 'data' => { 'secret_id' => 'n.minted' } }.to_json]
      end

      expect(described_class.generate_credential(accessor: 'legion')).to eq(
        lease_id: 'auth/nomad/cred/legion', lease_duration: 3600,
        renewable: true, data: { secret_id: 'n.minted' }
      )
      expect(method).to eq(:post)
    end
  end

  describe '#configure_access' do
    it 'returns the status for empty-body responses' do
      stubs.post('/v1/nomad/config/access') { [204, {}, ''] }

      expect(described_class.configure_access).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { described_class.configure_access(read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#read_config_access' do
    it 'returns the normalized access config' do
      stubs.get('/v1/nomad/config/access') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'address' => 'http://127.0.0.1:4646' } }.to_json]
      end

      expect(described_class.read_config_access).to eq(data: { address: 'http://127.0.0.1:4646' })
    end
  end

  describe '#configure_lease' do
    it 'returns the status for empty-body responses' do
      stubs.post('/v1/nomad/config/lease') { [204, {}, ''] }

      expect(described_class.configure_lease).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { described_class.configure_lease(read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#read_lease' do
    it 'returns the normalized lease config' do
      stubs.get('/v1/nomad/config/lease') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'ttl' => '1h' } }.to_json]
      end

      expect(described_class.read_lease).to eq(data: { ttl: '1h' })
    end
  end

  describe '#delete_lease' do
    it 'returns the status for empty-body responses' do
      stubs.delete('/v1/nomad/config/lease') { [204, {}, ''] }

      expect(described_class.delete_lease).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { described_class.delete_lease(read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end
end

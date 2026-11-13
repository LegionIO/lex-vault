# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Runners::System do
  let(:client) { Legion::Extensions::Vault::Client.new(token: 'test-token') }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new(url: 'http://127.0.0.1:8200') do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :test, stubs
    end
  end

  # connection: the standard pipe for ordinary methods. build_connection:
  # health/seal_status bypass the Raiser-registered pipe by design (their
  # non-200 statuses are data); the Raiser-bypass mechanism itself is covered
  # in helpers/client_spec.
  before do
    allow(client).to receive(:connection).and_return(test_connection)
    allow(client).to receive(:build_connection).and_return(test_connection)
  end

  describe '#health' do
    it 'returns the health body without raising on non-200 statuses' do
      stubs.get('/v1/sys/health') do
        [503, { 'Content-Type' => 'application/json' },
         { 'initialized' => true, 'sealed' => true, 'standby' => false }.to_json]
      end

      expect(client.health).to eq(initialized: true, sealed: true, standby: false)
    end
  end

  describe '#seal_status' do
    it 'returns the normalized seal status' do
      stubs.get('/v1/sys/seal-status') do
        [200, { 'Content-Type' => 'application/json' }, { 'sealed' => false, 't' => 3 }.to_json]
      end

      expect(client.seal_status).to eq(sealed: false, t: 3)
    end
  end

  describe '#unseal' do
    it 'returns the normalized unseal progress' do
      stubs.put('/v1/sys/unseal') do
        [200, { 'Content-Type' => 'application/json' }, { 'sealed' => false, 'progress' => 0 }.to_json]
      end

      expect(client.unseal(key: 'abc123')).to eq(sealed: false, progress: 0)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.unseal(key: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#list_mounts' do
    it 'returns the normalized mount table' do
      stubs.get('/v1/sys/mounts') do
        [200, { 'Content-Type' => 'application/json' }, { 'secret/' => { 'type' => 'kv' } }.to_json]
      end

      expect(client.list_mounts).to have_key(:'secret/')
    end
  end

  describe '#mount' do
    it 'returns the status for empty-body responses' do
      stubs.post('/v1/sys/mounts/pki') { [204, {}, ''] }

      expect(client.mount(path: 'pki', type: 'pki')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.mount(path: 'x', type: 'kv', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#unmount' do
    it 'returns the status for empty-body responses' do
      stubs.delete('/v1/sys/mounts/pki') { [204, {}, ''] }

      expect(client.unmount(path: 'pki')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.unmount(path: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#list_policies' do
    it 'returns the normalized policy list' do
      stubs.get('/v1/sys/policies/acl') do
        [200, { 'Content-Type' => 'application/json' }, { 'keys' => %w[default root] }.to_json]
      end

      expect(client.list_policies).to eq(keys: %w[default root])
    end
  end

  describe '#put_policy' do
    it 'returns the status for empty-body responses' do
      stubs.put('/v1/sys/policies/acl/my-policy') { [204, {}, ''] }

      expect(client.put_policy(name: 'my-policy', policy: 'path "secret/*" { capabilities = ["read"] }'))
        .to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.put_policy(name: 'x', policy: 'p', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#delete_policy' do
    it 'returns the status for empty-body responses' do
      stubs.delete('/v1/sys/policies/acl/my-policy') { [204, {}, ''] }

      expect(client.delete_policy(name: 'my-policy')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.delete_policy(name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end
end

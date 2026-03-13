# frozen_string_literal: true

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

  before { allow(client).to receive(:connection).and_return(test_connection) }

  describe '#health' do
    it 'returns health status' do
      stubs.get('/v1/sys/health') { [200, { 'Content-Type' => 'application/json' }, { 'initialized' => true, 'sealed' => false }] }
      result = client.health
      expect(result[:result]['initialized']).to be true
    end
  end

  describe '#seal_status' do
    it 'returns seal status' do
      stubs.get('/v1/sys/seal-status') { [200, { 'Content-Type' => 'application/json' }, { 'sealed' => false, 't' => 3 }] }
      result = client.seal_status
      expect(result[:result]['sealed']).to be false
    end
  end

  describe '#unseal' do
    it 'submits an unseal key' do
      stubs.put('/v1/sys/unseal') { [200, { 'Content-Type' => 'application/json' }, { 'sealed' => false, 'progress' => 0 }] }
      result = client.unseal(key: 'abc123')
      expect(result[:result]['sealed']).to be false
    end
  end

  describe '#list_mounts' do
    it 'returns mounted secrets engines' do
      stubs.get('/v1/sys/mounts') { [200, { 'Content-Type' => 'application/json' }, { 'secret/' => { 'type' => 'kv' } }] }
      result = client.list_mounts
      expect(result[:result]).to have_key('secret/')
    end
  end

  describe '#mount' do
    it 'mounts a secrets engine' do
      stubs.post('/v1/sys/mounts/pki') { [204, {}, ''] }
      result = client.mount(path: 'pki', type: 'pki')
      expect(result[:result]).to be true
    end
  end

  describe '#unmount' do
    it 'unmounts a secrets engine' do
      stubs.delete('/v1/sys/mounts/pki') { [204, {}, ''] }
      result = client.unmount(path: 'pki')
      expect(result[:result]).to be true
    end
  end

  describe '#list_policies' do
    it 'returns policies' do
      stubs.get('/v1/sys/policies/acl') do
        [200, { 'Content-Type' => 'application/json' }, { 'keys' => %w[default root] }]
      end
      result = client.list_policies
      expect(result[:result]['keys']).to include('default')
    end
  end

  describe '#put_policy' do
    it 'creates a policy' do
      stubs.put('/v1/sys/policies/acl/my-policy') { [204, {}, ''] }
      result = client.put_policy(name: 'my-policy', policy: 'path "secret/*" { capabilities = ["read"] }')
      expect(result[:result]).to be true
    end
  end

  describe '#delete_policy' do
    it 'deletes a policy' do
      stubs.delete('/v1/sys/policies/acl/my-policy') { [204, {}, ''] }
      result = client.delete_policy(name: 'my-policy')
      expect(result[:result]).to be true
    end
  end
end

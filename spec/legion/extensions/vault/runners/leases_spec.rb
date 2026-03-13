# frozen_string_literal: true

RSpec.describe Legion::Extensions::Vault::Runners::Leases do
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

  describe '#lookup_lease' do
    it 'looks up a lease' do
      stubs.put('/v1/sys/leases/lookup') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'id' => 'auth/token/create/abc', 'ttl' => 3600 } }]
      end
      result = client.lookup_lease(lease_id: 'auth/token/create/abc')
      expect(result[:result]['data']['ttl']).to eq(3600)
    end
  end

  describe '#renew_lease' do
    it 'renews a lease' do
      stubs.put('/v1/sys/leases/renew') do
        [200, { 'Content-Type' => 'application/json' }, { 'lease_id' => 'auth/token/create/abc', 'lease_duration' => 3600 }]
      end
      result = client.renew_lease(lease_id: 'auth/token/create/abc')
      expect(result[:result]['lease_duration']).to eq(3600)
    end
  end

  describe '#revoke_lease' do
    it 'revokes a lease' do
      stubs.put('/v1/sys/leases/revoke') { [204, {}, ''] }
      result = client.revoke_lease(lease_id: 'auth/token/create/abc')
      expect(result[:result]).to be true
    end
  end
end

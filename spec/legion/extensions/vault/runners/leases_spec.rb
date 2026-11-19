# frozen_string_literal: true

require 'faraday'

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
    it 'returns the normalized lease data' do
      stubs.put('/v1/sys/leases/lookup') do
        [200, { 'Content-Type' => 'application/json' },
         { 'data' => { 'id' => 'auth/token/create/abc', 'ttl' => 3600 } }.to_json]
      end

      expect(client.lookup_lease(lease_id: 'auth/token/create/abc'))
        .to eq(data: { id: 'auth/token/create/abc', ttl: 3600 })
    end
  end

  describe '#renew_lease' do
    it 'returns the normalized renewal' do
      stubs.put('/v1/sys/leases/renew') do
        [200, { 'Content-Type' => 'application/json' },
         { 'lease_id' => 'auth/token/create/abc', 'lease_duration' => 3600 }.to_json]
      end

      expect(client.renew_lease(lease_id: 'auth/token/create/abc'))
        .to eq(lease_id: 'auth/token/create/abc', lease_duration: 3600)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.renew_lease(lease_id: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#revoke_lease' do
    it 'returns the status for empty-body responses' do
      stubs.put('/v1/sys/leases/revoke') { [204, {}, ''] }

      expect(client.revoke_lease(lease_id: 'auth/token/create/abc')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.revoke_lease(lease_id: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end
end

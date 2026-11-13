# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Runners::Token do
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

  describe '#create_token' do
    it 'returns the normalized auth envelope' do
      stubs.post('/v1/auth/token/create') do
        [200, { 'Content-Type' => 'application/json' }, { 'auth' => { 'client_token' => 'new-token' } }.to_json]
      end

      expect(client.create_token(policies: ['default'], ttl: '1h'))
        .to eq(auth: { client_token: 'new-token' })
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.create_token(policies: ['default'], read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#lookup_self' do
    it 'returns the normalized token data' do
      stubs.get('/v1/auth/token/lookup-self') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'display_name' => 'root' } }.to_json]
      end

      expect(client.lookup_self).to eq(data: { display_name: 'root' })
    end
  end

  describe '#renew_self' do
    it 'returns the normalized auth envelope' do
      stubs.post('/v1/auth/token/renew-self') do
        [200, { 'Content-Type' => 'application/json' }, { 'auth' => { 'client_token' => 'test-token' } }.to_json]
      end

      expect(client.renew_self).to eq(auth: { client_token: 'test-token' })
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.renew_self(read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#revoke_token' do
    it 'returns the status for empty-body responses' do
      stubs.post('/v1/auth/token/revoke') { [204, {}, ''] }

      expect(client.revoke_token(token_to_revoke: 'old-token')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.revoke_token(token_to_revoke: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#list_token_roles' do
    it 'returns the normalized role list' do
      stubs.get('/v1/auth/token/roles') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => ['my-role'] } }.to_json]
      end

      expect(client.list_token_roles).to eq(data: { keys: ['my-role'] })
    end
  end

  describe '#delete_token_role' do
    it 'returns the status for empty-body responses' do
      stubs.delete('/v1/auth/token/roles/my-role') { [204, {}, ''] }

      expect(client.delete_token_role(role_name: 'my-role')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.delete_token_role(role_name: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end
end

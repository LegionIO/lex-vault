# frozen_string_literal: true

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
    it 'creates a new token' do
      stubs.post('/v1/auth/token/create') do
        [200, { 'Content-Type' => 'application/json' }, { 'auth' => { 'client_token' => 'new-token' } }]
      end
      result = client.create_token(policies: ['default'], ttl: '1h')
      expect(result[:result]['auth']['client_token']).to eq('new-token')
    end
  end

  describe '#lookup_self' do
    it 'returns info about the current token' do
      stubs.get('/v1/auth/token/lookup-self') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'display_name' => 'root' } }]
      end
      result = client.lookup_self
      expect(result[:result]['data']['display_name']).to eq('root')
    end
  end

  describe '#renew_self' do
    it 'renews the current token' do
      stubs.post('/v1/auth/token/renew-self') do
        [200, { 'Content-Type' => 'application/json' }, { 'auth' => { 'client_token' => 'test-token' } }]
      end
      result = client.renew_self
      expect(result[:result]['auth']['client_token']).to eq('test-token')
    end
  end

  describe '#revoke_token' do
    it 'revokes a specified token' do
      stubs.post('/v1/auth/token/revoke') { [204, {}, ''] }
      result = client.revoke_token(token_to_revoke: 'old-token')
      expect(result[:result]).to be true
    end
  end

  describe '#list_roles' do
    it 'lists token roles' do
      stubs.get('/v1/auth/token/roles') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => ['my-role'] } }]
      end
      result = client.list_roles
      expect(result[:result]['data']['keys']).to include('my-role')
    end
  end

  describe '#delete_role' do
    it 'deletes a token role' do
      stubs.delete('/v1/auth/token/roles/my-role') { [204, {}, ''] }
      result = client.delete_role(role_name: 'my-role')
      expect(result[:result]).to be true
    end
  end
end

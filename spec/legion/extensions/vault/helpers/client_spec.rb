# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Helpers::Client do
  subject(:helper) { Object.new.extend(described_class) }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  describe '#build_connection' do
    it 'targets the given address' do
      expect(helper.build_connection(address: 'https://vault.example.com').url_prefix.to_s)
        .to eq('https://vault.example.com/')
    end

    it 'sets the X-Vault-Token header when a token is given' do
      expect(helper.build_connection(address: 'http://127.0.0.1:8200', token: 's.t')
                   .headers['X-Vault-Token']).to eq('s.t')
    end

    it 'omits the X-Vault-Token header when no token is given' do
      expect(helper.build_connection(address: 'http://127.0.0.1:8200')
                   .headers['X-Vault-Token']).to be_nil
    end

    it 'sets the X-Vault-Namespace header when a namespace is given' do
      expect(helper.build_connection(address: 'http://127.0.0.1:8200', namespace: 'team/one')
                   .headers['X-Vault-Namespace']).to eq('team/one')
    end

    it 'omits the X-Vault-Namespace header when no namespace is given' do
      expect(helper.build_connection(address: 'http://127.0.0.1:8200')
                   .headers['X-Vault-Namespace']).to be_nil
    end

    it 'raises APIError on non-2xx responses' do
      stubs.get('/v1/deny') do
        [403, { 'Content-Type' => 'application/json' }, { 'errors' => ['permission denied'] }.to_json]
      end
      connection = helper.build_connection(address: 'http://127.0.0.1:8200', token: 's.t')
      connection.adapter :test, stubs

      expect { connection.get('/v1/deny') }
        .to raise_error(Legion::Extensions::Vault::Errors::APIError) do |error|
          expect(error.code).to eq(403)
          expect(error.message).to eq('permission denied')
        end
    end

    it 'skips the Raiser when raise_errors: false' do
      stubs.get('/v1/sys/health') do
        [503, { 'Content-Type' => 'application/json' }, { 'sealed' => true }.to_json]
      end
      connection = helper.build_connection(address: 'http://127.0.0.1:8200', token: 's.t', raise_errors: false)
      connection.adapter :test, stubs

      response = connection.get('/v1/sys/health')

      expect(response.status).to eq(503)
    end
  end

  describe '#vault_normalize' do
    it 'converts string keys to symbol keys recursively' do
      expect(helper.vault_normalize({ 'data' => { 'data' => { 'foo' => 'bar' } } }))
        .to eq({ data: { data: { foo: 'bar' } } })
    end
  end

  describe '#connection' do
    it 'resolves credentials and builds a Faraday connection' do
      connection = helper.connection(token: 's.explicit', namespace: 'a/b')

      expect(connection).to be_a(Faraday::Connection)
      expect(connection.headers['X-Vault-Token']).to eq('s.explicit')
      expect(connection.headers['X-Vault-Namespace']).to eq('a/b')
    end

    it 'uses the settings address by default' do
      expect(helper.connection(token: 's.t').url_prefix.to_s).to eq('http://127.0.0.1:8200/')
    end

    it 'raises AuthUnresolved when nothing resolves' do
      expect { helper.connection }
        .to raise_error(Legion::Extensions::Vault::Errors::AuthUnresolved)
    end
  end
end

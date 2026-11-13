# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Helpers::Auth do
  subject(:helper) { Object.new.extend(described_class) }

  describe '#default_credentials' do
    it 'reads the extension settings tree' do
      expect(helper.default_credentials).to eq(
        address: 'http://127.0.0.1:8200', token: nil, namespace: nil
      )
    end

    it 'reflects operator configuration' do
      Legion::Settings.loader.settings[:extensions][:vault][:token] = 's.configured'
      Legion::Settings.loader.settings[:extensions][:vault][:namespace] = 'team/one'

      expect(helper.default_credentials).to eq(
        address: 'http://127.0.0.1:8200', token: 's.configured', namespace: 'team/one'
      )
    end
  end

  describe '#auth_resolve' do
    it 'uses an explicit token when provided' do
      expect(helper.auth_resolve(token: 's.explicit')[:token]).to eq('s.explicit')
    end

    it 'falls back to the settings token' do
      Legion::Settings.loader.settings[:extensions][:vault][:token] = 's.configured'

      expect(helper.auth_resolve[:token]).to eq('s.configured')
    end

    it 'prefers the explicit token over settings' do
      Legion::Settings.loader.settings[:extensions][:vault][:token] = 's.configured'

      expect(helper.auth_resolve(token: 's.explicit')[:token]).to eq('s.explicit')
    end

    it 'overrides address and namespace from call-time opts' do
      resolved = helper.auth_resolve(token: 's.t', address: 'https://other', namespace: 'a/b')

      expect(resolved[:address]).to eq('https://other')
      expect(resolved[:namespace]).to eq('a/b')
    end

    it 'ignores nil call-time opts (compact merge)' do
      Legion::Settings.loader.settings[:extensions][:vault][:token] = 's.configured'

      resolved = helper.auth_resolve(token: nil, address: nil)

      expect(resolved[:token]).to eq('s.configured')
      expect(resolved[:address]).to eq('http://127.0.0.1:8200')
    end

    it 'raises AuthUnresolved when nothing is resolvable' do
      expect { helper.auth_resolve }
        .to raise_error(Legion::Extensions::Vault::Errors::AuthUnresolved)
    end

    context 'with an auth descriptor' do
      let(:stubs) { Faraday::Adapter::Test::Stubs.new }
      let(:test_connection) do
        Faraday.new(url: 'http://127.0.0.1:8200') do |conn|
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.adapter :test, stubs
        end
      end

      it 'mints a token via the user_pass runner' do
        stubs.post('/v1/auth/ldap/login') do
          [200, { 'Content-Type' => 'application/json' },
           { 'auth' => { 'client_token' => 's.minted', 'lease_id' => 'abc' } }.to_json]
        end
        allow(Legion::Extensions::Vault::Auth::Runners::UserPass)
          .to receive(:build_connection).and_return(test_connection)

        resolved = helper.auth_resolve(auth: { method: :user_pass, username: 'alice', password: 'wonderland' })

        expect(resolved[:token]).to eq('s.minted')
      end

      it 'mints a token via the app_role runner' do
        stubs.post('/v1/auth/approle/login') do
          [200, { 'Content-Type' => 'application/json' }, { 'auth' => { 'client_token' => 's.approle' } }.to_json]
        end
        allow(Legion::Extensions::Vault::Auth::Runners::AppRole)
          .to receive(:build_connection).and_return(test_connection)

        resolved = helper.auth_resolve(auth: { method: :app_role, role_id: 'r', secret_id: 's' })

        expect(resolved[:token]).to eq('s.approle')
      end

      it 'prefers an explicit token over an auth descriptor' do
        resolved = helper.auth_resolve(token: 's.explicit',
                                       auth:  { method: :user_pass, username: 'a', password: 'b' })

        expect(resolved[:token]).to eq('s.explicit')
      end

      it 'raises AuthUnresolved for an unsupported auth method' do
        expect { helper.auth_resolve(auth: { method: :jwt, jwt: 'x' }) }
          .to raise_error(Legion::Extensions::Vault::Errors::AuthUnresolved, /unsupported auth method: jwt/)
      end

      it 'raises AuthUnresolved when the login returns no client_token' do
        stubs.post('/v1/auth/approle/login') do
          [200, { 'Content-Type' => 'application/json' }, { 'auth' => {} }.to_json]
        end
        allow(Legion::Extensions::Vault::Auth::Runners::AppRole)
          .to receive(:build_connection).and_return(test_connection)

        expect { helper.auth_resolve(auth: { method: :app_role, role_id: 'r', secret_id: 's' }) }
          .to raise_error(Legion::Extensions::Vault::Errors::AuthUnresolved, /returned no client_token/)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Legion::Extensions::Vault::Runners::Pki do
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

  describe '#issue' do
    it 'issues a certificate' do
      stubs.post('/v1/pki/issue/web-server') do
        [200, { 'Content-Type' => 'application/json' },
         { 'data' => { 'certificate' => '-----BEGIN CERTIFICATE-----', 'serial_number' => '01:02:03' } }]
      end
      result = client.issue(role: 'web-server', common_name: 'example.com')
      expect(result[:result]['data']['certificate']).to start_with('-----BEGIN')
    end
  end

  describe '#sign_csr' do
    it 'signs a CSR' do
      stubs.post('/v1/pki/sign/web-server') do
        [200, { 'Content-Type' => 'application/json' },
         { 'data' => { 'certificate' => '-----BEGIN CERTIFICATE-----' } }]
      end
      result = client.sign_csr(role: 'web-server', csr: '-----BEGIN CERTIFICATE REQUEST-----', common_name: 'example.com')
      expect(result[:result]['data']['certificate']).to start_with('-----BEGIN')
    end
  end

  describe '#revoke' do
    it 'revokes a certificate' do
      stubs.post('/v1/pki/revoke') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'revocation_time' => 1_234_567_890 } }]
      end
      result = client.revoke(serial_number: '01:02:03')
      expect(result[:result]['data']['revocation_time']).to be_a(Integer)
    end
  end

  describe '#list_certs' do
    it 'lists certificate serial numbers' do
      stubs.get('/v1/pki/certs') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => ['01:02:03'] } }]
      end
      result = client.list_certs
      expect(result[:result]['data']['keys']).to include('01:02:03')
    end
  end

  describe '#ca_chain' do
    it 'returns the CA chain' do
      stubs.get('/v1/pki/ca_chain') do
        [200, { 'Content-Type' => 'application/json' }, '-----BEGIN CERTIFICATE-----']
      end
      result = client.ca_chain
      expect(result[:result]).not_to be_nil
    end
  end

  describe '#list_roles' do
    it 'lists PKI roles' do
      stubs.get('/v1/pki/roles') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => ['web-server'] } }]
      end
      result = client.list_roles
      expect(result[:result]['data']['keys']).to include('web-server')
    end
  end
end

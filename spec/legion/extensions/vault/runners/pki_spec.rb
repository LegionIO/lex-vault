# frozen_string_literal: true

require 'faraday'

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
    it 'returns the normalized certificate' do
      stubs.post('/v1/pki/issue/web-server') do
        [200, { 'Content-Type' => 'application/json' },
         { 'data' => { 'certificate' => '-----BEGIN CERTIFICATE-----', 'serial_number' => '01:02:03' } }.to_json]
      end

      expect(client.issue(role: 'web-server', common_name: 'example.com'))
        .to eq(data: { certificate: '-----BEGIN CERTIFICATE-----', serial_number: '01:02:03' })
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.issue(role: 'x', common_name: 'y', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#sign_csr' do
    it 'returns the normalized certificate' do
      stubs.post('/v1/pki/sign/web-server') do
        [200, { 'Content-Type' => 'application/json' },
         { 'data' => { 'certificate' => '-----BEGIN CERTIFICATE-----' } }.to_json]
      end

      expect(client.sign_csr(role: 'web-server', csr: '-----BEGIN CERTIFICATE REQUEST-----', common_name: 'example.com'))
        .to eq(data: { certificate: '-----BEGIN CERTIFICATE-----' })
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.sign_csr(role: 'x', csr: 'c', common_name: 'y', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#revoke' do
    it 'returns the normalized revocation' do
      stubs.post('/v1/pki/revoke') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'revocation_time' => 1_234_567_890 } }.to_json]
      end

      expect(client.revoke(serial_number: '01:02:03')).to eq(data: { revocation_time: 1_234_567_890 })
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.revoke(serial_number: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#list_certs' do
    it 'returns the normalized serial list' do
      stubs.get('/v1/pki/certs') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => ['01:02:03'] } }.to_json]
      end

      expect(client.list_certs).to eq(data: { keys: ['01:02:03'] })
    end
  end

  describe '#ca_chain' do
    it 'wraps the plain-text PEM body in a Hash' do
      stubs.get('/v1/pki/ca_chain') do
        [200, { 'Content-Type' => 'text/plain' }, '-----BEGIN CERTIFICATE-----']
      end

      expect(client.ca_chain).to eq(data: '-----BEGIN CERTIFICATE-----')
    end
  end

  describe '#list_pki_roles' do
    it 'returns the normalized role list' do
      stubs.get('/v1/pki/roles') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => ['web-server'] } }.to_json]
      end

      expect(client.list_pki_roles).to eq(data: { keys: ['web-server'] })
    end
  end
end

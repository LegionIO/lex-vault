# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/vault/runners/namespaces'

RSpec.describe Legion::Extensions::Vault::Runners::Namespaces do
  let(:client) { Legion::Extensions::Vault::Client.new(address: 'http://vault.test:8200', token: 'test-token') }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_conn) do
    Faraday.new do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :test, stubs
    end
  end

  before do
    allow(client).to receive(:connection).and_return(test_conn)
  end

  describe '#list_namespaces' do
    it 'returns list of namespace keys' do
      stubs.get('/v1/sys/namespaces') { [200, { 'Content-Type' => 'application/json' }, '{"keys":["ns1/","ns2/"]}'] }
      result = client.list_namespaces
      expect(result[:result]).to eq({ 'keys' => ['ns1/', 'ns2/'] })
    end
  end

  describe '#get_namespace' do
    it 'returns namespace details' do
      stubs.get('/v1/sys/namespaces/myns') do
        [200, { 'Content-Type' => 'application/json' }, '{"path":"myns/","id":"abc123"}']
      end
      result = client.get_namespace(name: 'myns')
      expect(result[:result]['path']).to eq('myns/')
    end
  end

  describe '#create_namespace' do
    it 'creates a namespace and returns success' do
      stubs.post('/v1/sys/namespaces/new-ns') { [200, { 'Content-Type' => 'application/json' }, '{}'] }
      result = client.create_namespace(name: 'new-ns')
      expect(result[:result]).to be_truthy
    end
  end

  describe '#delete_namespace' do
    it 'deletes a namespace and returns success' do
      stubs.delete('/v1/sys/namespaces/old-ns') { [204, {}, ''] }
      result = client.delete_namespace(name: 'old-ns')
      expect(result[:result]).to be true
    end
  end
end

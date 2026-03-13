# frozen_string_literal: true

RSpec.describe Legion::Extensions::Vault::Client do
  subject(:client) { described_class.new(token: 'test-token') }

  it 'stores configuration' do
    expect(client.opts[:token]).to eq('test-token')
    expect(client.opts[:address]).to eq('http://127.0.0.1:8200')
  end

  it 'accepts a custom address' do
    custom = described_class.new(token: 'tok', address: 'https://vault.example.com')
    expect(custom.opts[:address]).to eq('https://vault.example.com')
  end

  it 'accepts a namespace' do
    namespaced = described_class.new(token: 'tok', namespace: 'admin/team1')
    expect(namespaced.opts[:namespace]).to eq('admin/team1')
  end

  it 'returns a Faraday connection' do
    expect(client.connection).to be_a(Faraday::Connection)
  end
end

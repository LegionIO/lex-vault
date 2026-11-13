# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Auth::Helpers::Login do
  subject(:helper) { Object.new.extend(described_class) }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new(url: 'http://127.0.0.1:8200') do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :test, stubs
    end
  end

  let(:captured) { {} }

  before do
    stubs.post('/v1/auth/approle/login') do |env|
      captured[:body] = env[:body]
      [200, { 'Content-Type' => 'application/json' }, { 'auth' => { 'client_token' => 's.minted' } }.to_json]
    end
    allow(helper).to receive(:build_connection).and_return(test_connection)
  end

  it 'posts the body to /v1/auth/{mount}/login' do
    helper.vault_login(mount: 'approle', body: { role_id: 'r', secret_id: 's' })

    expect(Legion::JSON.load(captured[:body])).to eq(role_id: 'r', secret_id: 's')
  end

  it 'never passes a token to the connection builder' do
    helper.vault_login(mount: 'approle', body: { role_id: 'r', secret_id: 's' })

    expect(helper).to have_received(:build_connection).with(address: 'http://127.0.0.1:8200', namespace: nil)
  end

  it 'returns the raw parsed login body' do
    expect(helper.vault_login(mount: 'approle', body: { role_id: 'r', secret_id: 's' }))
      .to eq({ 'auth' => { 'client_token' => 's.minted' } })
  end
end

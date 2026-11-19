# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Auth::Runners::UserPass do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new(url: 'http://127.0.0.1:8200') do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :test, stubs
    end
  end

  def login_envelope
    { 'auth' => { 'client_token' => 's.minted', 'lease_id' => 'abc',
                  'lease_duration' => 3600, 'renewable' => true } }
  end

  let(:captured) { {} }

  before do
    stubs.post('/v1/auth/ldap/login') do |env|
      captured[:body] = env[:body]
      [200, { 'Content-Type' => 'application/json' }, login_envelope.to_json]
    end
    allow(described_class).to receive(:build_connection).and_return(test_connection)
  end

  it 'posts to the ldap login endpoint' do
    described_class.login(username: 'alice', password: 'wonderland')

    expect(captured[:body]).to be_a(String)
  end

  it 'sends the method-specific body' do
    described_class.login(username: 'alice', password: 'wonderland')

    expect(Legion::JSON.load(captured[:body])).to eq(username: 'alice', password: 'wonderland')
  end

  it 'never attaches a token to the login connection' do
    described_class.login(username: 'alice', password: 'wonderland')

    expect(described_class).to have_received(:build_connection).with(address: 'http://127.0.0.1:8200', namespace: nil)
  end

  it 'returns the normalized login envelope' do
    expect(described_class.login(username: 'alice', password: 'wonderland'))
      .to eq(auth: { client_token: 's.minted', lease_id: 'abc', lease_duration: 3600, renewable: true })
  end

  it 'honors a custom mount' do
    custom = {}
    stubs.post('/v1/auth/corp-ldap/login') do |env|
      custom[:body] = env[:body]
      [200, { 'Content-Type' => 'application/json' }, login_envelope.to_json]
    end

    described_class.login(username: 'alice', password: 'wonderland', mount: 'corp-ldap')

    expect(custom[:body]).to be_a(String)
  end
end

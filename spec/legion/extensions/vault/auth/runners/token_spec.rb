# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Auth::Runners::Token do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new(url: 'http://127.0.0.1:8200') do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :test, stubs
    end
  end

  def lookup_body
    { 'id' => 's.token', 'policies' => ['default'], 'explicit_max_ttl' => 0, 'renewable' => true }
  end

  let(:captured) { {} }

  before do
    stubs.post('/v1/auth/token/lookup') do |env|
      captured[:body] = env[:body]
      [200, { 'Content-Type' => 'application/json' }, lookup_body.to_json]
    end
    allow(described_class).to receive(:build_connection).and_return(test_connection)
  end

  it 'looks up the given token' do
    described_class.validate(token: 's.token')

    expect(captured[:body]).to be_a(String)
  end

  it 'sends the token in the lookup body' do
    described_class.validate(token: 's.token')

    expect(Legion::JSON.load(captured[:body])).to eq(token: 's.token')
  end

  it 'authenticates the lookup as the given token' do
    described_class.validate(token: 's.token')

    expect(described_class)
      .to have_received(:build_connection)
      .with(address: 'http://127.0.0.1:8200', token: 's.token', namespace: nil)
  end

  it 'returns the normalized lookup body' do
    expect(described_class.validate(token: 's.token'))
      .to eq(id: 's.token', policies: ['default'], explicit_max_ttl: 0, renewable: true)
  end
end

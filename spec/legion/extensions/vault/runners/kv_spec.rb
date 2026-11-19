# frozen_string_literal: true

require 'faraday'

RSpec.describe Legion::Extensions::Vault::Runners::Kv do
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

  describe '#read_secret' do
    it 'returns the normalized KV v2 envelope (symbol keys, no double-wrap)' do
      stubs.get('/v1/secret/data/my/secret') do
        [200, { 'Content-Type' => 'application/json' },
         { 'data' => { 'data' => { 'foo' => 'bar' }, 'metadata' => { 'version' => 1 } } }.to_json]
      end

      expect(client.read_secret(path: 'my/secret'))
        .to eq(data: { data: { foo: 'bar' }, metadata: { version: 1 } })
    end

    it 'passes the version query param when given' do
      url = nil
      stubs.get('/v1/secret/data/my/secret') do |env|
        url = env[:url]
        [200, { 'Content-Type' => 'application/json' }, {}.to_json]
      end

      client.read_secret(path: 'my/secret', version: 3)

      expect(url.query).to eq('version=3')
    end

    it 'honors a custom mount' do
      custom = nil
      stubs.get('/v1/other/data/x') do |env|
        custom = env
        [200, { 'Content-Type' => 'application/json' }, {}.to_json]
      end

      client.read_secret(path: 'x', mount: 'other')

      expect(custom).not_to be_nil
    end
  end

  describe '#write_secret' do
    it 'sends the data payload and returns the normalized body' do
      body = nil
      stubs.post('/v1/secret/data/my/secret') do |env|
        body = env[:body]
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'version' => 1 } }.to_json]
      end

      expect(client.write_secret(path: 'my/secret', data: { foo: 'bar' }))
        .to eq(data: { version: 1 })
      expect(Legion::JSON.load(body)).to eq(data: { foo: 'bar' })
    end

    it 'sends cas options when given' do
      body = nil
      stubs.post('/v1/secret/data/my/secret') do |env|
        body = env[:body]
        [200, { 'Content-Type' => 'application/json' }, {}.to_json]
      end

      client.write_secret(path: 'my/secret', data: { foo: 'bar' }, cas: 1)

      expect(Legion::JSON.load(body)).to eq(data: { foo: 'bar' }, options: { cas: 1 })
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.write_secret(path: 'x', data: { a: 1 }, read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#patch_secret' do
    it 'sends a merge-patch with an explicitly serialized body' do
      body = nil
      headers = nil
      stubs.patch('/v1/secret/data/my/secret') do |env|
        body = env[:body]
        headers = env[:request_headers]
        [204, {}, '']
      end

      client.patch_secret(path: 'my/secret', data: { foo: 'baz' })

      expect(headers['Content-Type']).to eq('application/merge-patch+json')
      expect(body).to be_a(String)
      expect(Legion::JSON.load(body)).to eq(data: { foo: 'baz' })
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.patch_secret(path: 'x', data: { a: 1 }, read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#delete_secret' do
    it 'returns the status for empty-body responses' do
      stubs.delete('/v1/secret/data/my/secret') { [204, {}, ''] }

      expect(client.delete_secret(path: 'my/secret')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.delete_secret(path: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#delete_versions' do
    it 'posts the versions list and returns the status' do
      body = nil
      stubs.post('/v1/secret/delete/my/secret') do |env|
        body = env[:body]
        [204, {}, '']
      end

      expect(client.delete_versions(path: 'my/secret', versions: [1, 2])).to eq(status: 204)
      expect(Legion::JSON.load(body)).to eq(versions: [1, 2])
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.delete_versions(path: 'x', versions: [1], read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#undelete_versions' do
    it 'posts the versions list and returns the status' do
      stubs.post('/v1/secret/undelete/my/secret') { [204, {}, ''] }

      expect(client.undelete_versions(path: 'my/secret', versions: [1])).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.undelete_versions(path: 'x', versions: [1], read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#destroy_versions' do
    it 'puts the versions list and returns the status' do
      stubs.put('/v1/secret/destroy/my/secret') { [204, {}, ''] }

      expect(client.destroy_versions(path: 'my/secret', versions: [1])).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.destroy_versions(path: 'x', versions: [1], read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#list_secrets' do
    it 'returns the normalized metadata list' do
      stubs.get('/v1/secret/metadata/my') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'keys' => %w[secret1 secret2] } }.to_json]
      end

      expect(client.list_secrets(path: 'my')).to eq(data: { keys: %w[secret1 secret2] })
    end
  end

  describe '#read_metadata' do
    it 'returns the normalized metadata' do
      stubs.get('/v1/secret/metadata/my/secret') do
        [200, { 'Content-Type' => 'application/json' }, { 'data' => { 'max_versions' => 10 } }.to_json]
      end

      expect(client.read_metadata(path: 'my/secret')).to eq(data: { max_versions: 10 })
    end
  end

  describe '#write_metadata' do
    it 'sends the provided options and returns the status' do
      body = nil
      stubs.post('/v1/secret/metadata/my/secret') do |env|
        body = env[:body]
        [204, {}, '']
      end

      expect(client.write_metadata(path: 'my/secret', max_versions: 5, cas_required: true))
        .to eq(status: 204)
      expect(Legion::JSON.load(body)).to eq(max_versions: 5, cas_required: true)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.write_metadata(path: 'x', max_versions: 5, read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end

  describe '#delete_metadata' do
    it 'returns the status for empty-body responses' do
      stubs.delete('/v1/secret/metadata/my/secret') { [204, {}, ''] }

      expect(client.delete_metadata(path: 'my/secret')).to eq(status: 204)
    end

    it 'raises ReadOnlyError in read_only mode' do
      expect { client.delete_metadata(path: 'x', read_only: true) }
        .to raise_error(Legion::Extensions::Vault::Errors::ReadOnlyError)
    end
  end
end

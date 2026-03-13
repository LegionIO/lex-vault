# frozen_string_literal: true

require 'faraday'

module Legion
  module Extensions
    module Vault
      module Helpers
        module Client
          def connection(address: 'http://127.0.0.1:8200', token: nil, namespace: nil, **_opts)
            Faraday.new(url: address) do |conn|
              conn.request :json
              conn.response :json, content_type: /\bjson$/
              conn.headers['X-Vault-Token'] = token if token
              conn.headers['X-Vault-Namespace'] = namespace if namespace
            end
          end
        end
      end
    end
  end
end

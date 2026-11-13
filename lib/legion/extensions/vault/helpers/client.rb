# frozen_string_literal: true

require 'faraday'
require 'legion/json'
require 'legion/json/helper'
require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/helpers/auth'

module Legion
  module Extensions
    module Vault
      module Helpers
        module Client
          include Legion::JSON::Helper
          include Legion::Extensions::Vault::Helpers::Auth

          # Pure Faraday builder. address is required — the resolver guarantees
          # presence. token: nil skips the header (the login path relies on it).
          # raise_errors: false is for informational endpoints whose non-200
          # statuses are data (sys/health, sys/seal-status).
          def build_connection(address:, token: nil, namespace: nil, raise_errors: true)
            Faraday.new(url: address) do |conn|
              conn.request :json
              conn.response :json, content_type: /\bjson$/
              conn.response :vault_raiser if raise_errors
              conn.headers['X-Vault-Token'] = token if token
              conn.headers['X-Vault-Namespace'] = namespace if namespace
            end
          end

          # The only pipe entry point for runner methods: resolve credentials,
          # build the connection. Runners never touch credential keys.
          def connection(**)
            resolved = auth_resolve(**)
            build_connection(address:   resolved[:address],
                             token:     resolved[:token],
                             namespace: resolved[:namespace])
          end

          # Symbol-key round-trip (workspace invariant). Works in framework,
          # spec, and standalone contexts.
          def vault_normalize(thing)
            json_load(json_dump(thing))
          end
        end
      end
    end
  end
end

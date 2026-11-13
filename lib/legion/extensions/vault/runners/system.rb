# frozen_string_literal: true

require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module System
          include Legion::Extensions::Vault::Helpers::Client

          # Informational: non-200 statuses (sealed, standby, uninit) are data,
          # so this bypasses the Raiser-registered pipe.
          def health(**)
            resolved = auth_resolve(**)
            body = build_connection(address: resolved[:address], token: resolved[:token],
                                    namespace: resolved[:namespace], raise_errors: false)
                   .get('/v1/sys/health').body
            vault_normalize(body)
          end

          def seal_status(**)
            resolved = auth_resolve(**)
            body = build_connection(address: resolved[:address], token: resolved[:token],
                                    namespace: resolved[:namespace], raise_errors: false)
                   .get('/v1/sys/seal-status').body
            vault_normalize(body)
          end

          def seal(read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).put('/v1/sys/seal').status }
          end

          def unseal(key:, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            vault_normalize(connection(**).put('/v1/sys/unseal', { key: key }).body)
          end

          def init(secret_shares: 5, secret_threshold: 3, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { secret_shares: secret_shares, secret_threshold: secret_threshold }
            vault_normalize(connection(**).put('/v1/sys/init', body).body)
          end

          def list_mounts(**)
            vault_normalize(connection(**).get('/v1/sys/mounts').body)
          end

          def mount(path:, type:, description: nil, config: nil, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { type: type, description: description, config: config }.compact
            { status: connection(**).post("/v1/sys/mounts/#{path}", body).status }
          end

          def unmount(path:, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/sys/mounts/#{path}").status }
          end

          def list_auth(**)
            vault_normalize(connection(**).get('/v1/sys/auth').body)
          end

          def enable_auth(path:, type:, description: nil, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { type: type, description: description }.compact
            { status: connection(**).post("/v1/sys/auth/#{path}", body).status }
          end

          def disable_auth(path:, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/sys/auth/#{path}").status }
          end

          def list_policies(**)
            vault_normalize(connection(**).get('/v1/sys/policies/acl').body)
          end

          def get_policy(name:, **)
            vault_normalize(connection(**).get("/v1/sys/policies/acl/#{name}").body)
          end

          def put_policy(name:, policy:, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).put("/v1/sys/policies/acl/#{name}", { policy: policy }).status }
          end

          def delete_policy(name:, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/sys/policies/acl/#{name}").status }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end

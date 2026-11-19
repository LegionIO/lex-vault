# frozen_string_literal: true

require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Token
          include Legion::Extensions::Vault::Helpers::Client

          def create_token(policies: nil, ttl: nil, renewable: nil, display_name: nil, role_name: nil, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { policies: policies, ttl: ttl, renewable: renewable, display_name: display_name }.compact
            path = role_name ? "/v1/auth/token/create/#{role_name}" : '/v1/auth/token/create'
            vault_normalize(connection(**).post(path, body).body)
          end

          def lookup_token(token_to_lookup:, **)
            vault_normalize(connection(**).post('/v1/auth/token/lookup', { token: token_to_lookup }).body)
          end

          def lookup_self(**)
            vault_normalize(connection(**).get('/v1/auth/token/lookup-self').body)
          end

          def renew_token(token_to_renew:, increment: nil, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { token: token_to_renew, increment: increment }.compact
            vault_normalize(connection(**).post('/v1/auth/token/renew', body).body)
          end

          def renew_self(increment: nil, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = increment ? { increment: increment } : {}
            vault_normalize(connection(**).post('/v1/auth/token/renew-self', body).body)
          end

          def revoke_token(token_to_revoke:, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).post('/v1/auth/token/revoke', { token: token_to_revoke }).status }
          end

          def revoke_self(read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).post('/v1/auth/token/revoke-self').status }
          end

          def list_accessors(**)
            vault_normalize(connection(**).get('/v1/auth/token/accessors', { list: true }).body)
          end

          def list_token_roles(**)
            vault_normalize(connection(**).get('/v1/auth/token/roles', { list: true }).body)
          end

          def get_token_role(role_name:, **)
            vault_normalize(connection(**).get("/v1/auth/token/roles/#{role_name}").body)
          end

          def create_token_role(role_name:, allowed_policies: nil, orphan: nil, renewable: nil, token_ttl: nil,
                                read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { allowed_policies: allowed_policies, orphan: orphan, renewable: renewable,
                     token_ttl: token_ttl }.compact
            { status: connection(**).post("/v1/auth/token/roles/#{role_name}", body).status }
          end

          def delete_token_role(role_name:, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/auth/token/roles/#{role_name}").status }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end

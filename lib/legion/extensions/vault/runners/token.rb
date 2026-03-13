# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Token
          include Legion::Extensions::Vault::Helpers::Client

          def create_token(policies: nil, ttl: nil, renewable: nil, display_name: nil, role_name: nil, **)
            body = { policies: policies, ttl: ttl, renewable: renewable, display_name: display_name }.compact
            path = role_name ? "/v1/auth/token/create/#{role_name}" : '/v1/auth/token/create'
            response = connection(**).post(path, body)
            { result: response.body }
          end

          def lookup_token(token_to_lookup:, **)
            response = connection(**).post('/v1/auth/token/lookup', { token: token_to_lookup })
            { result: response.body }
          end

          def lookup_self(**)
            response = connection(**).get('/v1/auth/token/lookup-self')
            { result: response.body }
          end

          def renew_token(token_to_renew:, increment: nil, **)
            body = { token: token_to_renew, increment: increment }.compact
            response = connection(**).post('/v1/auth/token/renew', body)
            { result: response.body }
          end

          def renew_self(increment: nil, **)
            body = increment ? { increment: increment } : {}
            response = connection(**).post('/v1/auth/token/renew-self', body)
            { result: response.body }
          end

          def revoke_token(token_to_revoke:, **)
            response = connection(**).post('/v1/auth/token/revoke', { token: token_to_revoke })
            { result: response.status == 204 }
          end

          def revoke_self(**)
            response = connection(**).post('/v1/auth/token/revoke-self')
            { result: response.status == 204 }
          end

          def list_accessors(**)
            response = connection(**).get('/v1/auth/token/accessors', { list: true })
            { result: response.body }
          end

          def list_roles(**)
            response = connection(**).get('/v1/auth/token/roles', { list: true })
            { result: response.body }
          end

          def get_role(role_name:, **)
            response = connection(**).get("/v1/auth/token/roles/#{role_name}")
            { result: response.body }
          end

          def create_role(role_name:, allowed_policies: nil, orphan: nil, renewable: nil, token_ttl: nil, **)
            body = { allowed_policies: allowed_policies, orphan: orphan, renewable: renewable,
                     token_ttl: token_ttl }.compact
            response = connection(**).post("/v1/auth/token/roles/#{role_name}", body)
            { result: response.status == 204 }
          end

          def delete_role(role_name:, **)
            response = connection(**).delete("/v1/auth/token/roles/#{role_name}")
            { result: response.status == 204 }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module System
          include Legion::Extensions::Vault::Helpers::Client

          def health(**)
            response = connection(**).get('/v1/sys/health')
            { result: response.body }
          end

          def seal_status(**)
            response = connection(**).get('/v1/sys/seal-status')
            { result: response.body }
          end

          def seal(**)
            response = connection(**).put('/v1/sys/seal')
            { result: response.status == 204 }
          end

          def unseal(key:, **)
            response = connection(**).put('/v1/sys/unseal', { key: key })
            { result: response.body }
          end

          def init(secret_shares: 5, secret_threshold: 3, **)
            body = { secret_shares: secret_shares, secret_threshold: secret_threshold }
            response = connection(**).put('/v1/sys/init', body)
            { result: response.body }
          end

          def list_mounts(**)
            response = connection(**).get('/v1/sys/mounts')
            { result: response.body }
          end

          def mount(path:, type:, description: nil, config: nil, **)
            body = { type: type, description: description, config: config }.compact
            response = connection(**).post("/v1/sys/mounts/#{path}", body)
            { result: response.status == 204 }
          end

          def unmount(path:, **)
            response = connection(**).delete("/v1/sys/mounts/#{path}")
            { result: response.status == 204 }
          end

          def list_auth(**)
            response = connection(**).get('/v1/sys/auth')
            { result: response.body }
          end

          def enable_auth(path:, type:, description: nil, **)
            body = { type: type, description: description }.compact
            response = connection(**).post("/v1/sys/auth/#{path}", body)
            { result: response.status == 204 }
          end

          def disable_auth(path:, **)
            response = connection(**).delete("/v1/sys/auth/#{path}")
            { result: response.status == 204 }
          end

          def list_policies(**)
            response = connection(**).get('/v1/sys/policies/acl')
            { result: response.body }
          end

          def get_policy(name:, **)
            response = connection(**).get("/v1/sys/policies/acl/#{name}")
            { result: response.body }
          end

          def put_policy(name:, policy:, **)
            response = connection(**).put("/v1/sys/policies/acl/#{name}", { policy: policy })
            { result: response.status == 204 }
          end

          def delete_policy(name:, **)
            response = connection(**).delete("/v1/sys/policies/acl/#{name}")
            { result: response.status == 204 }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)
        end
      end
    end
  end
end

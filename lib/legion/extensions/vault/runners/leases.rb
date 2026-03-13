# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Leases
          include Legion::Extensions::Vault::Helpers::Client

          def lookup_lease(lease_id:, **)
            response = connection(**).put('/v1/sys/leases/lookup', { lease_id: lease_id })
            { result: response.body }
          end

          def renew_lease(lease_id:, increment: nil, **)
            body = { lease_id: lease_id, increment: increment }.compact
            response = connection(**).put('/v1/sys/leases/renew', body)
            { result: response.body }
          end

          def revoke_lease(lease_id:, **)
            response = connection(**).put('/v1/sys/leases/revoke', { lease_id: lease_id })
            { result: response.status == 204 }
          end

          def list_leases(prefix:, **)
            response = connection(**).get("/v1/sys/leases/lookup/#{prefix}", { list: true })
            { result: response.body }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)
        end
      end
    end
  end
end

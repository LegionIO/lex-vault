# frozen_string_literal: true

require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Leases
          include Legion::Extensions::Vault::Helpers::Client

          def lookup_lease(lease_id:, **)
            vault_normalize(connection(**).put('/v1/sys/leases/lookup', { lease_id: lease_id }).body)
          end

          def renew_lease(lease_id:, increment: nil, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { lease_id: lease_id, increment: increment }.compact
            vault_normalize(connection(**).put('/v1/sys/leases/renew', body).body)
          end

          def revoke_lease(lease_id:, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).put('/v1/sys/leases/revoke', { lease_id: lease_id }).status }
          end

          def list_leases(prefix:, **)
            vault_normalize(connection(**).get("/v1/sys/leases/lookup/#{prefix}", { list: true }).body)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end

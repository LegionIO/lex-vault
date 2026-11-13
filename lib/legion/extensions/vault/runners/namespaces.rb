# frozen_string_literal: true

require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Namespaces
          include Legion::Extensions::Vault::Helpers::Client

          def list_namespaces(**)
            vault_normalize(connection(**).get('/v1/sys/namespaces').body)
          end

          def get_namespace(name:, **)
            vault_normalize(connection(**).get("/v1/sys/namespaces/#{name}").body)
          end

          def create_namespace(name:, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            vault_normalize(connection(**).post("/v1/sys/namespaces/#{name}").body)
          end

          def delete_namespace(name:, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/sys/namespaces/#{name}").status }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end

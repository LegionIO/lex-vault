# frozen_string_literal: true

require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Nomad
          include Legion::Extensions::Vault::Helpers::Client

          def create_role(name:, policies: nil, global: true, type: 'management', mount: 'nomad', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { name: name, policies: policies, global: global, type: type }
            { status: connection(**).post("/v1/#{mount}/role/#{name}", body).status }
          end

          def read_role(name:, mount: 'nomad', **)
            vault_normalize(connection(**).get("/v1/#{mount}/role/#{name}").body)
          end

          def list_roles(mount: 'nomad', **)
            vault_normalize(connection(**).get("/v1/#{mount}/role", { list: true }).body)
          end

          def delete_role(name:, mount: 'nomad', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/#{mount}/role/#{name}").status }
          end

          # Nomad mints credentials via POST /cred/{accessor} — unlike the
          # GET /creds/{role} shape of the other dynamic engines.
          def generate_credential(accessor:, mount: 'nomad', **)
            vault_normalize(connection(**).post("/v1/#{mount}/cred/#{accessor}").body)
          end

          def configure_access(mount: 'nomad', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).post("/v1/#{mount}/config/access", {}).status }
          end

          def read_config_access(mount: 'nomad', **)
            vault_normalize(connection(**).get("/v1/#{mount}/config/access").body)
          end

          def configure_lease(mount: 'nomad', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).post("/v1/#{mount}/config/lease", {}).status }
          end

          def read_lease(mount: 'nomad', **)
            vault_normalize(connection(**).get("/v1/#{mount}/config/lease").body)
          end

          def delete_lease(mount: 'nomad', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/#{mount}/config/lease").status }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end

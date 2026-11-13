# frozen_string_literal: true

require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Consul
          include Legion::Extensions::Vault::Helpers::Client

          # The Consul server's own token is a business kwarg (consul_token:) —
          # it is not the Vault credential pipe's token.
          # rubocop:disable Metrics/ParameterLists -- the Vault consul config/access schema
          def configure(address:, consul_token:, scheme: 'https', ca_cert: nil, client_cert: nil, client_key: nil,
                        mount: 'consul', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { address: address, scheme: scheme, token: consul_token,
                     ca_cert: ca_cert, client_cert: client_cert, client_key: client_key }.compact
            { status: connection(**).post("/v1/#{mount}/config/access", body).status }
          end
          # rubocop:enable Metrics/ParameterLists

          # rubocop:disable Metrics/ParameterLists -- the Vault consul role schema
          def create_role(name:, partition: 'default', node_identities: nil, consul_namespace: nil,
                          consul_roles: nil, service_identities: nil, consul_policies: nil, local: true,
                          ttl: '31d', max_ttl: '1y', mount: 'consul', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { partition: partition, node_identities: node_identities, consul_namespace: consul_namespace,
                     consul_roles: consul_roles, service_identities: service_identities,
                     consul_policies: consul_policies, local: local, ttl: ttl, max_ttl: max_ttl }.compact
            { status: connection(**).post("/v1/#{mount}/roles/#{name}", body).status }
          end
          # rubocop:enable Metrics/ParameterLists

          def read_role(name:, mount: 'consul', **)
            vault_normalize(connection(**).get("/v1/#{mount}/roles/#{name}").body)
          end

          def list_roles(mount: 'consul', **)
            vault_normalize(connection(**).get("/v1/#{mount}/roles", { list: true }).body)
          end

          def delete_role(name:, mount: 'consul', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            { status: connection(**).delete("/v1/#{mount}/roles/#{name}").status }
          end

          def generate_credential(role:, mount: 'consul', **)
            vault_normalize(connection(**).get("/v1/#{mount}/creds/#{role}").body)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end

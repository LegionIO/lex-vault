# frozen_string_literal: true

require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Pki
          include Legion::Extensions::Vault::Helpers::Client

          def issue(role:, common_name:, mount: 'pki', alt_names: nil, ttl: nil, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { common_name: common_name, alt_names: alt_names, ttl: ttl }.compact
            vault_normalize(connection(**).post("/v1/#{mount}/issue/#{role}", body).body)
          end

          def sign_csr(role:, csr:, common_name:, mount: 'pki', alt_names: nil, ttl: nil, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { csr: csr, common_name: common_name, alt_names: alt_names, ttl: ttl }.compact
            vault_normalize(connection(**).post("/v1/#{mount}/sign/#{role}", body).body)
          end

          def revoke(serial_number:, mount: 'pki', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            vault_normalize(connection(**).post("/v1/#{mount}/revoke", { serial_number: serial_number }).body)
          end

          def list_certs(mount: 'pki', **)
            vault_normalize(connection(**).get("/v1/#{mount}/certs", { list: true }).body)
          end

          def get_cert(serial:, mount: 'pki', **)
            vault_normalize(connection(**).get("/v1/#{mount}/cert/#{serial}").body)
          end

          # Plain-text PEM endpoint: the body is not JSON, so it is wrapped to
          # keep the runner-returns-Hash contract.
          def ca_chain(mount: 'pki', **)
            body = connection(**).get("/v1/#{mount}/ca_chain").body
            body.is_a?(Hash) ? vault_normalize(body) : { data: body }
          end

          def list_pki_roles(mount: 'pki', **)
            vault_normalize(connection(**).get("/v1/#{mount}/roles", { list: true }).body)
          end

          def get_pki_role(role_name:, mount: 'pki', **)
            vault_normalize(connection(**).get("/v1/#{mount}/roles/#{role_name}").body)
          end

          def create_pki_role(role_name:, allowed_domains: nil, allow_subdomains: nil, max_ttl: nil,
                              mount: 'pki', read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { allowed_domains: allowed_domains, allow_subdomains: allow_subdomains,
                     max_ttl: max_ttl }.compact
            { status: connection(**).post("/v1/#{mount}/roles/#{role_name}", body).status }
          end

          def tidy(mount: 'pki', tidy_cert_store: true, tidy_revoked_certs: true, read_only: false, **)
            raise Legion::Extensions::Vault::Errors::ReadOnlyError, 'write operations disabled (read_only mode)' if read_only

            body = { tidy_cert_store: tidy_cert_store, tidy_revoked_certs: tidy_revoked_certs }
            vault_normalize(connection(**).post("/v1/#{mount}/tidy", body).body)
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)
        end
      end
    end
  end
end

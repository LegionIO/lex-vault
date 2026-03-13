# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Pki
          include Legion::Extensions::Vault::Helpers::Client

          def issue(role:, common_name:, mount: 'pki', alt_names: nil, ttl: nil, **)
            body = { common_name: common_name, alt_names: alt_names, ttl: ttl }.compact
            response = connection(**).post("/v1/#{mount}/issue/#{role}", body)
            { result: response.body }
          end

          def sign_csr(role:, csr:, common_name:, mount: 'pki', alt_names: nil, ttl: nil, **)
            body = { csr: csr, common_name: common_name, alt_names: alt_names, ttl: ttl }.compact
            response = connection(**).post("/v1/#{mount}/sign/#{role}", body)
            { result: response.body }
          end

          def revoke(serial_number:, mount: 'pki', **)
            response = connection(**).post("/v1/#{mount}/revoke", { serial_number: serial_number })
            { result: response.body }
          end

          def list_certs(mount: 'pki', **)
            response = connection(**).get("/v1/#{mount}/certs", { list: true })
            { result: response.body }
          end

          def get_cert(serial:, mount: 'pki', **)
            response = connection(**).get("/v1/#{mount}/cert/#{serial}")
            { result: response.body }
          end

          def ca_chain(mount: 'pki', **)
            response = connection(**).get("/v1/#{mount}/ca_chain")
            { result: response.body }
          end

          def list_roles(mount: 'pki', **)
            response = connection(**).get("/v1/#{mount}/roles", { list: true })
            { result: response.body }
          end

          def get_role(role_name:, mount: 'pki', **)
            response = connection(**).get("/v1/#{mount}/roles/#{role_name}")
            { result: response.body }
          end

          def create_role(role_name:, mount: 'pki', allowed_domains: nil, allow_subdomains: nil, max_ttl: nil, **)
            body = { allowed_domains: allowed_domains, allow_subdomains: allow_subdomains,
                     max_ttl: max_ttl }.compact
            response = connection(**).post("/v1/#{mount}/roles/#{role_name}", body)
            { result: response.status == 204 }
          end

          def tidy(mount: 'pki', tidy_cert_store: true, tidy_revoked_certs: true, **)
            body = { tidy_cert_store: tidy_cert_store, tidy_revoked_certs: tidy_revoked_certs }
            response = connection(**).post("/v1/#{mount}/tidy", body)
            { result: response.body }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)
        end
      end
    end
  end
end

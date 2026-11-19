# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Auth
        module Helpers
          module Login
            include Legion::Extensions::Vault::Helpers::Client

            # Shared login for the mint-based auth methods. Bypasses
            # auth_resolve on purpose: a login call must not re-enter
            # resolution, and it never carries a token — that's what we're
            # minting. Returns the raw parsed body; the runner normalizes.
            def vault_login(mount:, body:, **opts)
              base = default_credentials.merge(opts.compact)
              build_connection(address: base[:address], namespace: base[:namespace])
                .post("/v1/auth/#{mount}/login", body).body
            end
          end
        end
      end
    end
  end
end

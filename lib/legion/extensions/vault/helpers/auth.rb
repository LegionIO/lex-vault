# frozen_string_literal: true

require 'legion/settings'
require 'legion/extensions/vault/errors'

module Legion
  module Extensions
    module Vault
      module Helpers
        module Auth
          # Resolve credentials for a single call. Precedence: explicit token:
          # > auth: descriptor > settings (spec §4.3). The returned hash is the
          # complete credential context; a minted token is ephemeral (C4).
          def auth_resolve(**opts)
            resolved = default_credentials.merge(opts.slice(:address, :token, :namespace, :auth).compact)

            return resolved if resolved[:token]

            descriptor = resolved[:auth]
            if descriptor.is_a?(Hash) && descriptor[:method]
              runner = auth_dispatch.fetch(descriptor[:method]) do
                raise Legion::Extensions::Vault::Errors::AuthUnresolved,
                      "unsupported auth method: #{descriptor[:method]}"
              end
              response = runner.login(**descriptor.except(:method),
                                      address:   resolved[:address],
                                      namespace: resolved[:namespace])
              # Vault's login envelope is contract-guaranteed: auth.client_token
              # on success. The Raiser means non-2xx never reaches here.
              token = response[:auth][:client_token]
              unless token
                raise Legion::Extensions::Vault::Errors::AuthUnresolved,
                      "auth method #{descriptor[:method]} returned no client_token"
              end

              # Ephemeral (C4): the minted token exists only in this return
              # value. Nothing memoizes, caches, or retains it.
              resolved[:token] = token
              return resolved
            end

            raise Legion::Extensions::Vault::Errors::AuthUnresolved,
                  'no vault credentials resolvable (token, auth descriptor, or settings)'
          end

          # Auth method → runner module. Lazy: no load-order fragility, and the
          # set changes with deferred methods (Jwt/K8s/Tls). Direct module
          # call — the same send the framework uses, minus the tasker (D2).
          def auth_dispatch
            {
              user_pass: Legion::Extensions::Vault::Auth::Runners::UserPass,
              app_role:  Legion::Extensions::Vault::Auth::Runners::AppRole
            }
          end

          # The base credential context. Pure bracket access — build_settings
          # guarantees Legion::Settings[:extensions][:vault] with defaults in any
          # framework context. Client overrides this to return @opts (spec §7).
          def default_credentials
            vault = Legion::Settings[:extensions][:vault]
            { address: vault[:address], token: vault[:token], namespace: vault[:namespace] }
          end
        end
      end
    end
  end
end

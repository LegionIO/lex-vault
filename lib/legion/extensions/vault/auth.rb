# frozen_string_literal: true

require 'legion/extensions/vault/auth/helpers/login'
require 'legion/extensions/vault/auth/runners/token'
require 'legion/extensions/vault/auth/runners/user_pass'
require 'legion/extensions/vault/auth/runners/app_role'

module Legion
  module Extensions
    module Vault
      module Auth
        extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false

        # Declared independently of the root Vault extension: singleton
        # methods do not cross nested module boundaries. Same rationale —
        # no AMQP/meta-actor dispatch surface for the auth runners.
        def self.remote_invocable?
          false
        end

        def self.default_settings
          {
            runners: {
              token:     { desc: 'Validate a Vault token' },
              user_pass: { desc: 'LDAP login (username/password)' },
              app_role:  { desc: 'AppRole login (role_id/secret_id)' }
            }
          }
        end
      end
    end
  end
end

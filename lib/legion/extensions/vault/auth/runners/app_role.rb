# frozen_string_literal: true

require 'legion/extensions/vault/auth/helpers/login'

module Legion
  module Extensions
    module Vault
      module Auth
        module Runners
          module AppRole
            include Legion::Extensions::Vault::Auth::Helpers::Login

            def login(role_id:, secret_id:, mount: 'approle', **)
              vault_normalize(vault_login(mount: mount,
                                          body:  { role_id: role_id, secret_id: secret_id },
                                          **))
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end

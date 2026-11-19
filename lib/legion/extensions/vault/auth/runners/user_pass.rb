# frozen_string_literal: true

require 'legion/extensions/vault/auth/helpers/login'

module Legion
  module Extensions
    module Vault
      module Auth
        module Runners
          module UserPass
            include Legion::Extensions::Vault::Auth::Helpers::Login

            def login(username:, password:, mount: 'ldap', **)
              vault_normalize(vault_login(mount: mount,
                                          body:  { username: username, password: password },
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

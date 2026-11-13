# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Auth
        module Runners
          module Token
            include Legion::Extensions::Vault::Helpers::Client

            def validate(token:, **)
              vault_normalize(connection(token: token, **).post('/v1/auth/token/lookup', { token: token }).body)
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'

module Legion
  module Extensions
    module Vault
      module Runners
        module Namespaces
          include Legion::Extensions::Vault::Helpers::Client

          def list_namespaces(**)
            response = connection(**).get('/v1/sys/namespaces')
            { result: response.body }
          end

          def get_namespace(name:, **)
            response = connection(**).get("/v1/sys/namespaces/#{name}")
            { result: response.body }
          end

          def create_namespace(name:, **)
            response = connection(**).post("/v1/sys/namespaces/#{name}")
            { result: response.body }
          end

          def delete_namespace(name:, **)
            response = connection(**).delete("/v1/sys/namespaces/#{name}")
            { result: response.status == 204 }
          end

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)
        end
      end
    end
  end
end

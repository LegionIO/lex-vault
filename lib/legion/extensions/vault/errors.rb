# frozen_string_literal: true

require 'faraday'
require 'legion/json'
require 'legion/json/helper'

module Legion
  module Extensions
    module Vault
      module Errors
        class AuthUnresolved < StandardError; end
        class ReadOnlyError < StandardError; end

        class APIError < StandardError
          attr_reader :code

          def initialize(code, message)
            @code = code
            super(message)
          end
        end

        class Raiser < Faraday::Middleware
          include Legion::JSON::Helper

          def on_complete(env)
            status = env[:status].to_i
            return if status < 400

            raise APIError.new(status, message_from(env[:body]))
          end

          private

          def message_from(body)
            return 'vault error' unless body.is_a?(String) && !body.empty?

            parsed = json_load(body)
            errors = parsed[:errors] if parsed.is_a?(Hash)
            errors.is_a?(Array) && errors.first.is_a?(String) ? errors.first : 'vault error'
          end
        end

        Faraday::Response.register_middleware(vault_raiser: Raiser)
      end
    end
  end
end

# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'
require 'legion/extensions/vault/runners/system'
require 'legion/extensions/vault/runners/kv'
require 'legion/extensions/vault/runners/token'
require 'legion/extensions/vault/runners/transit'
require 'legion/extensions/vault/runners/pki'
require 'legion/extensions/vault/runners/leases'

module Legion
  module Extensions
    module Vault
      class Client
        include Helpers::Client
        include Runners::System
        include Runners::Kv
        include Runners::Token
        include Runners::Transit
        include Runners::Pki
        include Runners::Leases
        include Runners::Namespaces

        attr_reader :opts

        def initialize(address: 'http://127.0.0.1:8200', token: nil, namespace: nil, **extra)
          @opts = { address: address, token: token, namespace: namespace, **extra }
        end

        def connection(**override)
          super(**@opts.merge(override))
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'legion/extensions/vault/helpers/client'
require 'legion/extensions/vault/runners/system'
require 'legion/extensions/vault/runners/kv'
require 'legion/extensions/vault/runners/token'
require 'legion/extensions/vault/runners/transit'
require 'legion/extensions/vault/runners/pki'
require 'legion/extensions/vault/runners/leases'
require 'legion/extensions/vault/runners/namespaces'

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

        # The dynamic engines (Consul/Nomad) and the auth runners are not
        # mixed in: they share generic method names (create_role/login, ...)
        # that would shadow each other in one class. They are framework-level
        # units (own meta-actors/MCP surface); standalone auth uses the
        # auth: descriptor (Client.new(auth: { method: :user_pass, ... })).

        attr_reader :opts

        def initialize(address: 'http://127.0.0.1:8200', token: nil, namespace: nil, **extra)
          @opts = { address: address, token: token, namespace: namespace, **extra }
        end

        # Standalone base: the constructor kwargs ARE the credential context.
        # Overrides Helpers::Auth#default_credentials so standalone execution
        # never touches Legion::Settings (spec §7).
        def default_credentials
          @opts
        end
      end
    end
  end
end

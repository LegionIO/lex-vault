# frozen_string_literal: true

require 'legion/extensions/vault/version'
require 'legion/extensions/vault/errors'
require 'legion/extensions/vault/auth'
require 'legion/extensions/vault/helpers/auth'
require 'legion/extensions/vault/helpers/client'
require 'legion/extensions/vault/runners/system'
require 'legion/extensions/vault/runners/kv'
require 'legion/extensions/vault/runners/token'
require 'legion/extensions/vault/runners/transit'
require 'legion/extensions/vault/runners/pki'
require 'legion/extensions/vault/runners/leases'
require 'legion/extensions/vault/runners/namespaces'
require 'legion/extensions/vault/runners/consul'
require 'legion/extensions/vault/runners/nomad'
require 'legion/extensions/vault/client'

module Legion
  module Extensions
    module Vault
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false

      def self.default_settings
        {
          address:   'http://127.0.0.1:8200',
          token:     nil,
          namespace: nil,
          runners:   {
            kv:         { desc: 'KV v2 secret engine operations' },
            token:      { desc: 'Token auth engine management' },
            transit:    { desc: 'Transit encryption engine operations' },
            pki:        { desc: 'PKI certificate engine operations' },
            leases:     { desc: 'Lease lookup, renewal, and revocation' },
            namespaces: { desc: 'Enterprise namespace management' },
            system:     { desc: 'Vault system and mount administration' }
          }
        }
      end
    end
  end
end

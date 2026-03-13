# frozen_string_literal: true

require 'legion/extensions/vault/version'
require 'legion/extensions/vault/helpers/client'
require 'legion/extensions/vault/runners/system'
require 'legion/extensions/vault/runners/kv'
require 'legion/extensions/vault/runners/token'
require 'legion/extensions/vault/runners/transit'
require 'legion/extensions/vault/runners/pki'
require 'legion/extensions/vault/runners/leases'
require 'legion/extensions/vault/client'

module Legion
  module Extensions
    module Vault
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end

# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'legion/logging'
require 'legion/settings'
require 'legion/cache/helper'
require 'legion/crypt/helper'
require 'legion/data/helper'
require 'legion/json/helper'
require 'legion/transport'

module Legion
  module Extensions
    module Helpers
      module Lex
        include Legion::Logging::Helper
        include Legion::Settings::Helper
        include Legion::Cache::Helper
        include Legion::Crypt::Helper
        include Legion::Data::Helper
        include Legion::JSON::Helper
        include Legion::Transport::Helper

        # Mirror of the framework's dispatch mechanism: runner modules are
        # invoked at module level (runner_class.send(function, **args)), which
        # requires the module to extend itself.
        def self.included(base)
          base.extend base if base.instance_of?(Module)
        end
      end
    end
  end
end

require 'legion/extensions/vault'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  config.before do
    @original_extensions = Legion::Settings.loader.settings[:extensions]
    Legion::Settings.loader.settings[:extensions] = {
      vault: Legion::Extensions::Vault.default_settings
    }
  end

  config.after do
    Legion::Settings.loader.settings[:extensions] = @original_extensions
  end
end

# frozen_string_literal: true

require_relative 'lib/legion/extensions/vault/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-vault'
  spec.version       = Legion::Extensions::Vault::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Vault'
  spec.description   = 'Connects LegionIO to HashiCorp Vault'
  spec.homepage      = 'https://github.com/LegionIO/lex-vault'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LegionIO/lex-vault'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-vault'
  spec.metadata['changelog_uri'] = 'https://github.com/LegionIO/lex-vault'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LegionIO/lex-vault/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '>= 2.0'
end

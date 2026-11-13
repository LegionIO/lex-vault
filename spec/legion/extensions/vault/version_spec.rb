# frozen_string_literal: true

RSpec.describe 'Legion::Extensions::Vault::VERSION' do
  it 'has a semantic version number' do
    expect(Legion::Extensions::Vault::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end

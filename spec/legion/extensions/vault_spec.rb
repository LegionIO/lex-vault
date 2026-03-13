# frozen_string_literal: true

RSpec.describe Legion::Extensions::Vault do
  it 'has a version number' do
    expect(Legion::Extensions::Vault::VERSION).not_to be_nil
  end

  it 'defines the Client class' do
    expect(Legion::Extensions::Vault::Client).to be_a(Class)
  end
end
